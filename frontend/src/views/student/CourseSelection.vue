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
      time_slots: [],
      teachers: []
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
  return `周${days[slot.day_of_week - 1]} 第${slot.period}节`
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
  padding-bottom: 20px;
}

.main-card {
  border: none;
  background: transparent;
}

.main-card :deep(.el-card__header) {
  background: #fff;
  border-radius: 8px 8px 0 0;
  border-bottom: 1px solid #ebeef5;
  padding: 16px 24px;
}

.main-card :deep(.el-card__body) {
  background: transparent;
  padding: 20px 0 0 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-title {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.custom-tabs {
  background: #fff;
  padding: 0 24px;
  margin-bottom: 20px;
  border-radius: 0 0 8px 8px;
}

.tab-label {
  display: flex;
  align-items: center;
  gap: 6px;
}

.tab-badge {
  margin-left: 4px;
}

.search-bar {
  background: #fff;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  display: flex;
  gap: 20px;
  align-items: center;
  flex-wrap: wrap;
}

.search-input {
  width: 300px;
}

.filter-group {
  display: flex;
  gap: 12px;
}

.course-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.course-card {
  height: 100%;
  display: flex;
  flex-direction: column;
  transition: all 0.3s;
  border: none;
  border-radius: 12px;
}

.course-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
}

.course-card.is-full {
  opacity: 0.8;
  background-color: #f5f7fa;
}

.course-card.is-conflict {
  border: 1px solid #fde2e2;
}

.course-header {
  padding: 16px 16px 12px;
  border-bottom: 1px solid #ebeef5;
  margin-bottom: 0;
}

.course-title-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 4px;
}

.course-name {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  line-height: 1.4;
  flex: 1;
  margin-right: 8px;
}

.course-id {
  font-size: 12px;
  color: #909399;
  font-family: monospace;
}

.course-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 12px 16px;
}

.info-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 13px;
  color: #606266;
}

.info-item .el-icon {
  margin-top: 2px;
}

.time-slots {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.quota-progress {
  margin-top: 8px;
}

.progress-label {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #909399;
  margin-bottom: 4px;
}

.text-danger { color: #f56c6c; }
.text-warning { color: #e6a23c; }
.text-success { color: #67c23a; }

.course-footer {
  padding: 12px 16px 16px;
  border-top: 1px solid #ebeef5;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
}

.credits {
  display: flex;
  align-items: baseline;
  gap: 4px;
}

.credit-num {
  font-size: 20px;
  font-weight: bold;
  color: var(--primary-color);
}

.credit-label {
  font-size: 12px;
  color: #909399;
}

.select-btn {
  padding: 8px 24px;
}
</style>
