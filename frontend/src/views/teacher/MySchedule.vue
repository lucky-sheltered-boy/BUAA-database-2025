<template>
  <div class="my-schedule">
    <el-card class="main-card" shadow="never">
      <template #header>
        <div class="card-header">
          <div class="header-left">
            <span class="header-title">我的授课安排</span>
            <el-tag type="primary" effect="plain" class="count-tag">
              共 {{ groupedCourses.length }} 门课程
            </el-tag>
          </div>
          <div class="header-actions">
            <el-button type="primary" @click="fetchSchedule" :loading="loading" plain>
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
          </div>
        </div>
      </template>

      <div v-loading="loading" class="schedule-container">
        <el-empty 
          v-if="!loading && scheduleData.length === 0" 
          description="暂无授课安排"
        />

        <template v-else>
          <!-- 课程列表视图 -->
          <div class="course-list">
            <el-row :gutter="20">
              <el-col 
                v-for="(course, index) in groupedCourses" 
                :key="index"
                :xs="24" :sm="12" :md="8" :lg="6"
                class="course-col"
              >
                <el-card class="course-card" shadow="hover">
                  <div class="course-header">
                    <div class="header-main">
                      <h3 class="course-title" :title="course.course_name">{{ course.course_name }}</h3>
                      <el-tag type="primary" size="small" effect="plain">{{ course.course_id }}</el-tag>
                    </div>
                  </div>

                  <div class="course-body">
                    <div class="stats-container">
                      <div class="stat-row">
                        <span class="stat-label">选课人数</span>
                        <div class="stat-value-group">
                          <span class="current">{{ course.enrolled_students }}</span>
                          <span class="separator">/</span>
                          <span class="total">{{ course.capacity }}</span>
                        </div>
                      </div>
                      <el-progress 
                        :percentage="Math.min((course.enrolled_students / course.capacity) * 100, 100)"
                        :status="getProgressStatus(course)"
                        :stroke-width="4"
                        :show-text="false"
                      />
                    </div>

                    <div class="info-grid">
                      <div class="info-item">
                        <el-icon><Location /></el-icon>
                        <span>{{ course.building }} {{ course.room }}</span>
                      </div>
                    </div>

                    <div class="time-slots">
                      <div v-for="(slot, idx) in course.time_slots" :key="idx" class="time-slot-tag">
                        <el-icon><Timer /></el-icon>
                        <span>{{ formatTimeSlot(slot) }}</span>
                      </div>
                    </div>
                  </div>

                  <div class="course-footer">
                    <el-button 
                      type="primary" 
                      link 
                      @click="viewStudents(course)"
                    >
                      查看学生名单 <el-icon class="el-icon--right"><ArrowRight /></el-icon>
                    </el-button>
                  </div>
                </el-card>
              </el-col>
            </el-row>
          </div>

          <!-- 课表视图 -->
          <div class="timetable-view">
            <div class="timetable-header">
              <div class="corner-cell">时间/星期</div>
              <div v-for="day in weekDays" :key="day" class="header-cell">{{ day }}</div>
            </div>
            <div class="timetable-body">
              <div v-for="period in 13" :key="period" class="timetable-row">
                <div class="period-cell">第{{ period }}节</div>
                <div v-for="day in 7" :key="day" class="content-cell">
                  <div 
                    v-if="getCourseAt(day, period)"
                    class="course-block"
                    :style="getCourseStyle(getCourseAt(day, period))"
                    @click="viewStudents(getCourseAt(day, period))"
                  >
                    <div class="course-name-mini">{{ getCourseAt(day, period).course_name }}</div>
                    <div class="course-loc-mini">
                      {{ getCourseAt(day, period).building }} {{ getCourseAt(day, period).room }}
                    </div>
                    <div class="course-count-mini">
                      {{ getCourseAt(day, period).enrolled_students }}人
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useSemesterStore } from '@/stores/semester'
import { getWeekdayIndex } from '@/utils/helpers'
import { ElMessage } from 'element-plus'
import request from '@/utils/request'
import { Refresh, Location, Timer, ArrowRight } from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()
const semesterStore = useSemesterStore()
const loading = ref(false)
const scheduleData = ref([])
const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
const colors = [
  '#e1f3d8', '#faecd8', '#d9ecff', '#fde2e2', 
  '#e9e9eb', '#d1edc4', '#e8d6f9', '#c6e2ff'
]

// 按课程分组的数据（用于列表显示）
const groupedCourses = computed(() => {
  const map = new Map()
  scheduleData.value.forEach(item => {
    if (!map.has(item.instance_id)) {
      map.set(item.instance_id, {
        ...item,
        time_slots: []
      })
    }
    map.get(item.instance_id).time_slots.push({
      weekday: item.weekday,
      start_time: item.start_time,
      end_time: item.end_time
    })
  })
  return Array.from(map.values())
})

const fetchSchedule = async () => {
  loading.value = true
  try {
    const res = await request.get(`/teachers/${authStore.userId}/schedule`, { 
      params: { semester_id: semesterStore.currentSemesterId } 
    })
    scheduleData.value = Array.isArray(res) ? res : []
  } catch (error) {
    console.error('获取课表失败:', error)
    ElMessage.error('获取课表失败')
  } finally {
    loading.value = false
  }
}

const formatTimeSlot = (slot) => {
  if (!slot) return ''
  const idx = getWeekdayIndex(slot.weekday)
  const days = ['一', '二', '三', '四', '五', '六', '日']
  const dayText = idx >= 1 && idx <= 7 ? `周${days[idx - 1]}` : slot.weekday || ''
  return `${dayText} ${slot.start_time}-${slot.end_time}`
}

const getCourseAt = () => {
  return undefined
}

const getCourseStyle = (course) => {
  const index = course.course_id.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0) % colors.length
  return {
    backgroundColor: colors[index],
    color: '#606266',
    borderLeft: `3px solid ${colors[index].replace('0.1', '1').replace('d8', 'b0')}`,
    cursor: 'pointer'
  }
}

const getProgressStatus = (course) => {
  const total = course.total_quota ?? course.capacity ?? 0
  const enrolled = course.enrolled_students ?? 0
  const percentage = total > 0 ? enrolled / total : 0
  if (percentage >= 1) return 'exception'
  if (percentage >= 0.8) return 'warning'
  return 'success'
}

const viewStudents = (course) => {
  router.push({
    name: 'StudentList',
    params: { instanceId: course.instance_id }
  })
}

onMounted(() => {
  fetchSchedule()
})
</script>

<style scoped>
.my-schedule {
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

/* 修复课程卡片样式 */
.course-card :deep(.el-card__body) {
  padding: 0 !important;
  display: flex;
  flex-direction: column;
  height: 100%;
}

.course-header {
  padding: 16px 16px 12px;
  border-bottom: 1px solid #ebeef5;
}

.course-body {
  padding: 12px 16px;
  flex: 1;
}

.course-footer {
  padding: 12px 16px 16px;
  border-top: 1px solid #ebeef5;
  text-align: right;
  margin-top: auto;
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

.course-list {
  margin-bottom: 24px;
}

.course-col {
  margin-bottom: 20px;
}

.course-card {
  height: 100%;
  border-radius: 8px;
  border: none;
  transition: all 0.3s;
  display: flex;
  flex-direction: column;
}

.course-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.course-header {
  padding-bottom: 12px;
  border-bottom: 1px solid #f0f2f5;
  margin-bottom: 12px;
}

.header-main {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 8px;
}

.course-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.course-body {
  flex: 1;
}

.stats-container {
  margin-bottom: 16px;
  background-color: #f9fafc;
  padding: 12px;
  border-radius: 6px;
}

.stat-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
  font-size: 12px;
}

.stat-label {
  color: #909399;
}

.stat-value-group {
  font-family: monospace;
}

.current {
  font-weight: 600;
  color: #303133;
}

.separator {
  margin: 0 2px;
  color: #c0c4cc;
}

.total {
  color: #909399;
}

.info-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 8px;
  margin-bottom: 12px;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #606266;
}

.time-slots {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.time-slot-tag {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  background-color: #f0f2f5;
  border-radius: 4px;
  font-size: 12px;
  color: #909399;
}

.course-footer {
  /* padding 已在上面定义 */
}

/* 课表视图样式 */
.timetable-view {
  background: #fff;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #ebeef5;
}

.timetable-header {
  display: grid;
  grid-template-columns: 80px repeat(7, 1fr);
  background-color: #f5f7fa;
  border-bottom: 1px solid #ebeef5;
}

.corner-cell {
  padding: 12px;
  text-align: center;
  font-size: 12px;
  color: #909399;
  border-right: 1px solid #ebeef5;
  display: flex;
  align-items: center;
  justify-content: center;
}

.header-cell {
  padding: 12px;
  text-align: center;
  font-weight: 600;
  color: #303133;
  border-right: 1px solid #ebeef5;
}

.header-cell:last-child {
  border-right: none;
}

.timetable-body {
  display: flex;
  flex-direction: column;
}

.timetable-row {
  display: grid;
  grid-template-columns: 80px repeat(7, 1fr);
  border-bottom: 1px solid #ebeef5;
  min-height: 60px;
}

.timetable-row:last-child {
  border-bottom: none;
}

.period-cell {
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #fcfcfc;
  color: #909399;
  font-size: 12px;
  border-right: 1px solid #ebeef5;
}

.content-cell {
  border-right: 1px solid #ebeef5;
  padding: 4px;
  position: relative;
}

.content-cell:last-child {
  border-right: none;
}

.course-block {
  height: 100%;
  padding: 6px;
  border-radius: 4px;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  overflow: hidden;
  transition: all 0.2s;
}

.course-block:hover {
  filter: brightness(0.95);
  transform: scale(1.02);
  z-index: 1;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.course-name-mini {
  font-weight: 600;
  line-height: 1.2;
}

.course-loc-mini {
  font-size: 11px;
  opacity: 0.8;
}

.course-count-mini {
  font-size: 10px;
  margin-top: auto;
  text-align: right;
  opacity: 0.7;
}
</style>
