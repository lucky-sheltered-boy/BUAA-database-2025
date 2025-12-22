<template>
  <div class="course-selection">
    <el-card class="main-card" shadow="never">
      <template #header>
        <div class="card-header">
          <div class="header-left">
            <span class="header-title">选课中心</span>
            <el-tag :type="statsTagType" effect="plain" class="count-tag">
              共 {{ filteredCourses.length }} 门课程
            </el-tag>
          </div>
          <div class="header-actions">
            <el-button type="primary" @click="fetchCourses" :loading="loading" plain>
              <el-icon><Refresh /></el-icon>
              刷新列表
            </el-button>
          </div>
        </div>
      </template>

      <!-- 标签页切换 -->
      <el-tabs v-model="activeTab" class="custom-tabs">
        <el-tab-pane name="all">
          <template #label>
            <span class="tab-label">
              <el-icon><Grid /></el-icon>
              全部课程
              <el-badge :value="courses.length" :max="99" class="tab-badge" type="info" />
            </span>
          </template>
        </el-tab-pane>
        
        <el-tab-pane name="internal">
          <template #label>
            <span class="tab-label">
              <el-icon><School /></el-icon>
              本院系课程
              <el-badge :value="internalCourses.length" :max="99" type="success" class="tab-badge" />
            </span>
          </template>
        </el-tab-pane>
        
        <el-tab-pane name="external">
          <template #label>
            <span class="tab-label">
              <el-icon><Connection /></el-icon>
              跨专业课程
              <el-badge :value="externalCourses.length" :max="99" type="warning" class="tab-badge" />
            </span>
          </template>
        </el-tab-pane>
      </el-tabs>

      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-input
          v-model="searchQuery"
          placeholder="搜索课程名称、教师或教室..."
          prefix-icon="Search"
          clearable
          class="search-input"
        />
        <div class="filter-group">
          <el-checkbox v-model="showAvailableOnly" label="仅显示可选" border />
          <el-checkbox v-model="showConflictFree" label="不显示冲突" border />
        </div>
      </div>

      <!-- 课程列表 -->
      <div class="course-grid" v-loading="loading">
        <el-empty v-if="filteredCourses.length === 0" description="暂无符合条件的课程" />
        
        <div 
          v-for="course in filteredCourses" 
          :key="course.instance_id"
          class="course-card-wrapper"
        >
          <el-card 
            class="course-card" 
            :class="{ 
              'is-full': course.enrolled >= course.quota,
              'is-conflict': checkTimeConflict(course)
            }"
            shadow="hover"
            :body-style="{ padding: '0px', display: 'flex', flexDirection: 'column', height: '100%' }"
          >
            <div class="course-header">
              <div class="course-title-row">
                <h3 class="course-name">{{ course.course_name }}</h3>
                <el-tag size="small" :type="course.is_internal ? 'success' : 'warning'" effect="light">
                  {{ course.is_internal ? '本院' : '外院' }}
                </el-tag>
              </div>
              <div class="course-id">ID: {{ course.course_id }}</div>
            </div>

            <div class="course-body">
              <div class="info-item">
                <el-icon><User /></el-icon>
                <span class="teacher-names">{{ formatTeachers(course.teachers) }}</span>
              </div>
              
              <div class="info-item">
                <el-icon><Location /></el-icon>
                <span>{{ course.building }} {{ course.room_number }}</span>
              </div>

              <div class="info-item time-info">
                <el-icon><Timer /></el-icon>
                <div class="time-slots">
                  <div v-for="(slot, idx) in course.time_slots" :key="idx" class="time-slot">
                    {{ formatTimeSlot(slot) }}
                  </div>
                </div>
              </div>

              <div class="quota-progress">
                <div class="progress-label">
                  <span>选课人数</span>
                  <span :class="getQuotaClass(course)">
                    {{ course.enrolled }} / {{ course.quota }}
                  </span>
                </div>
                <el-progress 
                  :percentage="Math.min((course.enrolled / course.quota) * 100, 100)" 
                  :status="getProgressStatus(course)"
                  :stroke-width="6"
                  :show-text="false"
                />
              </div>
            </div>

            <div class="course-footer">
              <div class="credits">
                <span class="credit-num">{{ course.credits }}</span>
                <span class="credit-label">学分</span>
              </div>
              <el-button 
                type="primary" 
                :disabled="!canSelect(course)"
                :loading="selectingId === course.instance_id"
                @click="handleSelect(course)"
                class="select-btn"
              >
                {{ getButtonText(course) }}
              </el-button>
            </div>
          </el-card>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useSemesterStore } from '@/stores/semester'
import { useAuthStore } from '@/stores/auth'
import request from '@/utils/request'
import { 
  Refresh, Grid, School, Connection, Search,
  User, Location, Timer
} from '@element-plus/icons-vue'

const authStore = useAuthStore()
const semesterStore = useSemesterStore()
const loading = ref(false)
const selectingId = ref(null)
const courses = ref([])
const activeTab = ref('all')
const searchQuery = ref('')
const showAvailableOnly = ref(false)
const showConflictFree = ref(false)

// 模拟已选课程时间表（实际应从后端获取）
const mySchedule = ref([])

const internalCourses = computed(() => courses.value.filter(c => c.is_internal))
const externalCourses = computed(() => courses.value.filter(c => !c.is_internal))

const statsTagType = computed(() => {
  if (activeTab.value === 'internal') return 'success'
  if (activeTab.value === 'external') return 'warning'
  return 'info'
})

const filteredCourses = computed(() => {
  let result = courses.value

  // 标签筛选
  if (activeTab.value === 'internal') {
    result = result.filter(c => c.is_internal)
  } else if (activeTab.value === 'external') {
    result = result.filter(c => !c.is_internal)
  }

  // 搜索筛选
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(c => 
      c.course_name.toLowerCase().includes(query) ||
      (Array.isArray(c.teachers) && c.teachers.some(t => (t.name || '').toLowerCase().includes(query))) ||
      (c.building || '').toLowerCase().includes(query)
    )
  }

  // 仅显示可选
  if (showAvailableOnly.value) {
    result = result.filter(c => c.enrolled < c.quota)
  }

  // 不显示冲突
  if (showConflictFree.value) {
    result = result.filter(c => !checkTimeConflict(c))
  }

  return result
})

const fetchCourses = async () => {
  loading.value = true
  try {
    const res = await request.get(`/students/${authStore.userId}/available-courses`, {
      params: { semester_id: semesterStore.currentSemesterId }
    })
    // 将后端返回字段映射为前端使用结构
    const list = Array.isArray(res) ? res : []
    courses.value = list.map(c => ({
      instance_id: c.instance_id,
      course_id: c.course_id,
      course_name: c.course_name,
      credits: c.credit,
      is_internal: c.enroll_type === '本院系',
      building: c.building,
      room_number: c.room,
      quota: c.total_quota ?? 0,
      enrolled: (c.total_quota ?? 0) - (c.remaining_quota ?? 0),
      time_slots: c.time_slots || [],
      teachers: c.teachers || []
    }))
    
    // 同时获取已选课程以检测冲突
    await request.get(`/students/${authStore.userId}/schedule`, {
      params: { semester_id: semesterStore.currentSemesterId }
    })
    // 由于课表返回具体时间，暂不做节次级别冲突判断
    mySchedule.value = []
  } catch (error) {
    console.error('获取课程失败:', error)
    ElMessage.error('获取课程列表失败')
  } finally {
    loading.value = false
  }
}

const formatTeachers = (teachers) => {
  return teachers.map(t => t.name).join(', ')
}

const formatTimeSlot = (slot) => {
  const days = ['一', '二', '三', '四', '五', '六', '日']
  const dayIndex = parseInt(slot.day_of_week) - 1
  const dayName = days[dayIndex] || slot.day_of_week
  
  if (slot.start_time && slot.end_time) {
    return `${dayName} ${slot.start_time}-${slot.end_time}`
  }
  return `${dayName} 第${slot.period}节`
}

const getQuotaClass = (course) => {
  if (course.enrolled >= course.quota) return 'text-danger'
  if (course.enrolled >= course.quota * 0.8) return 'text-warning'
  return 'text-success'
}

const getProgressStatus = (course) => {
  if (course.enrolled >= course.quota) return 'exception'
  if (course.enrolled >= course.quota * 0.8) return 'warning'
  return 'success'
}

const checkTimeConflict = (course) => {
  // 暂无节次数据，跳过冲突检测
  return false
}

const canSelect = (course) => {
  if (course.enrolled >= course.quota) return false
  if (checkTimeConflict(course)) return false
  // 检查是否已选
  if (mySchedule.value.some(c => c.course_id === course.course_id)) return false
  return true
}

const getButtonText = (course) => {
  if (mySchedule.value.some(c => c.course_id === course.course_id)) return '已选'
  if (course.enrolled >= course.quota) return '已满'
  if (checkTimeConflict(course)) return '冲突'
  return '选课'
}

const handleSelect = async (course) => {
  ElMessageBox.confirm(
    `确定要选择课程 "${course.course_name}" 吗？`,
    '选课确认',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'info',
    }
  ).then(async () => {
    selectingId.value = course.instance_id
    try {
      await request.post(`/students/${authStore.userId}/enroll`, {
        instance_id: course.instance_id
      })
      ElMessage.success('选课成功')
      fetchCourses() // 刷新列表
    } catch (error) {
      ElMessage.error(error.response?.data?.detail || '选课失败')
    } finally {
      selectingId.value = null
    }
  })
}

onMounted(() => {
  fetchCourses()
})
</script>

<style scoped>
.course-selection {
  padding-bottom: 24px;
}

.main-card {
  border: none;
  background: transparent;
}

.main-card :deep(.el-card__header) {
  background: transparent;
  border: none;
  padding: 0;
  margin-bottom: 24px;
}

.main-card :deep(.el-card__body) {
  background: transparent;
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.header-title {
  font-size: 24px;
  font-weight: 600;
  color: #1f1f1f;
}

.count-tag {
  font-size: 13px;
  border-radius: 12px;
  padding: 0 12px;
}

.custom-tabs {
  margin-bottom: 24px;
  background: #fff;
  padding: 6px 6px 0;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.tab-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  padding: 8px 0;
}

.tab-badge :deep(.el-badge__content) {
  transform: translateY(-2px) translateX(5px);
}

.search-bar {
  background: #fff;
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
  flex-wrap: wrap;
  gap: 16px;
}

.search-input {
  width: 320px;
}

.search-input :deep(.el-input__wrapper) {
  border-radius: 8px;
  box-shadow: 0 0 0 1px #d9d9d9 inset;
}

.search-input :deep(.el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 1px var(--primary-color) inset;
}

.filter-group {
  display: flex;
  gap: 12px;
}

.course-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 24px;
}

.course-card-wrapper {
  height: 100%;
}

.course-card {
  height: 100%;
  display: flex;
  flex-direction: column;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid #f0f0f0;
  border-radius: 16px;
  overflow: hidden;
  background: #fff;
}

.course-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.08) !important;
  border-color: transparent;
}

.course-card.is-full {
  opacity: 0.85;
  background-color: #fafafa;
}

.course-card.is-conflict {
  border: 1px solid #ffccc7;
  background-color: #fff1f0;
}

.course-header {
  padding: 20px 20px 16px;
  border-bottom: 1px solid #f5f5f5;
  background: linear-gradient(to bottom, #fafafa, #fff);
}

.course-title-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 8px;
}

.course-name {
  margin: 0;
  font-size: 17px;
  font-weight: 600;
  color: #1f1f1f;
  line-height: 1.4;
  flex: 1;
  margin-right: 12px;
}

.course-id {
  font-size: 13px;
  color: #8c8c8c;
  font-family: 'SF Mono', Consolas, monospace;
  background: #f5f5f5;
  padding: 2px 6px;
  border-radius: 4px;
  width: fit-content;
}

.course-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px 20px;
}

.info-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  font-size: 14px;
  color: #595959;
}

.info-item .el-icon {
  margin-top: 3px;
  color: #8c8c8c;
}

.time-slots {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.quota-progress {
  margin-top: 8px;
  background: #fafafa;
  padding: 12px;
  border-radius: 8px;
}

.progress-label {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  color: #595959;
  margin-bottom: 6px;
  font-weight: 500;
}

.text-danger { color: #ff4d4f; }
.text-warning { color: #faad14; }
.text-success { color: #52c41a; }

.course-footer {
  padding: 16px 20px;
  border-top: 1px solid #f5f5f5;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
  background: #fff;
}

.credits {
  display: flex;
  align-items: baseline;
  gap: 4px;
}

.credit-num {
  font-size: 24px;
  font-weight: 700;
  color: var(--primary-color);
  font-family: 'Segoe UI', Roboto, sans-serif;
}

.credit-label {
  font-size: 13px;
  color: #8c8c8c;
}

.select-btn {
  padding: 10px 24px;
  border-radius: 8px;
  font-weight: 500;
  transition: all 0.2s;
}

.select-btn:not(:disabled):hover {
  transform: scale(1.02);
}
</style>
