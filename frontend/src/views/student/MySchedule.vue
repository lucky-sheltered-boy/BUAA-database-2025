<template>
  <div class="my-schedule">
    <el-card class="main-card" shadow="never">
      <template #header>
        <div class="card-header">
          <div class="header-left">
            <span class="header-title">我的课表</span>
            <el-tag type="success" effect="plain" class="count-tag">
              已选 {{ groupedCourses.length }} 门课程
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
          description="暂无课程安排"
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
                <el-card class="schedule-card" shadow="hover">
                  <div class="schedule-header">
                    <div class="header-main">
                      <h3 class="course-title" :title="course.course_name">{{ course.course_name }}</h3>
                      <el-tag type="success" size="small" effect="plain">{{ course.credit }}学分</el-tag>
                    </div>
                  </div>

                  <div class="schedule-body">
                    <div class="info-grid">
                      <div class="info-item">
                        <el-icon><Reading /></el-icon>
                        <span>{{ course.course_id }}</span>
                      </div>
                      <div class="info-item">
                        <el-icon><User /></el-icon>
                        <span>{{ course.teacher_name }}</span>
                      </div>
                      <div class="info-item">
                        <el-icon><Location /></el-icon>
                        <span>{{ course.location }}</span>
                      </div>
                    </div>

                    <div class="time-slots">
                      <div v-for="(slot, idx) in course.time_slots" :key="idx" class="time-slot-tag">
                        <el-icon><Timer /></el-icon>
                        <span>{{ formatTimeSlot(slot) }}</span>
                      </div>
                    </div>
                    
                    <div class="action-area">
                      <el-button 
                        type="danger" 
                        size="small" 
                        plain 
                        @click="handleDropCourse(course)"
                      >
                        退课
                      </el-button>
                    </div>
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
                  >
                    <div class="course-name-mini">{{ getCourseAt(day, period).course_name }}</div>
                    <div class="course-loc-mini">{{ getCourseAt(day, period).location }}</div>
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
import { ElMessage, ElMessageBox } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { useSemesterStore } from '@/stores/semester'
import { getWeekdayIndex } from '@/utils/helpers'
import request from '@/utils/request'
import { dropCourse } from '@/api'
import { Refresh, Reading, User, Location, Timer } from '@element-plus/icons-vue'

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
    if (!map.has(item.course_id)) {
      map.set(item.course_id, {
        instance_id: item.instance_id,
        course_id: item.course_id,
        course_name: item.course_name,
        teacher_name: item.teacher_name,
        credit: item.credit,
        location: `${item.building} ${item.room}`,
        time_slots: []
      })
    }
    map.get(item.course_id).time_slots.push({
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
    const res = await request.get(`/students/${authStore.userId}/schedule`, {
      params: { semester_id: semesterStore.currentSemesterId }
    })
    // res 为数组（request.js 已返回 data）
    scheduleData.value = Array.isArray(res) ? res : []
  } catch (error) {
    console.error('获取课表失败:', error)
    ElMessage.error('获取课表失败')
  } finally {
    loading.value = false
  }
}

const handleDropCourse = (course) => {
  ElMessageBox.confirm(
    `确定要退选课程 "${course.course_name}" 吗？`,
    '退课确认',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await dropCourse(authStore.userId, course.instance_id)
      ElMessage.success('退课成功')
      fetchSchedule() // 刷新课表
    } catch (error) {
      // 错误已在拦截器处理
    }
  })
}

const formatTimeSlot = (slot) => {
  if (!slot) return ''
  // 后端提供 weekday（如“星期一”）与 start/end_time
  const idx = getWeekdayIndex(slot.weekday)
  const days = ['一', '二', '三', '四', '五', '六', '日']
  const dayText = idx >= 1 && idx <= 7 ? `周${days[idx - 1]}` : slot.weekday || ''
  return `${dayText} ${slot.start_time}-${slot.end_time}`
}

// 由于后端返回的是具体时间（非第几节），这里不在课表栅格中匹配“第几节”，
// timetable 仍显示，但不渲染块（避免空转/报错）。
const getCourseAt = (day, period) => {
  return scheduleData.value.find(course => {
    const courseDayIdx = getWeekdayIndex(course.weekday)
    if (courseDayIdx !== day) return false
    
    // 简单的映射逻辑：根据开始时间的小时数判断节次
    // 假设：8:00=1-2节, 10:00=3-4节, 14:00=5-6节, 16:00=7-8节, 19:00=9-10节
    const startHour = parseInt(course.start_time.split(':')[0])
    let startPeriod = 0
    let endPeriod = 0
    
    if (startHour === 8) { startPeriod = 1; endPeriod = 2 }
    else if (startHour === 10) { startPeriod = 3; endPeriod = 4 }
    else if (startHour === 14) { startPeriod = 5; endPeriod = 6 }
    else if (startHour === 16) { startPeriod = 7; endPeriod = 8 }
    else if (startHour === 19) { startPeriod = 9; endPeriod = 10 }
    
    return period >= startPeriod && period <= endPeriod
  })
}

const getCourseStyle = (course) => {
  // 根据课程ID生成固定的颜色索引
  const index = course.course_id.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0) % colors.length
  return {
    backgroundColor: colors[index],
    color: '#606266',
    borderLeft: `3px solid ${colors[index].replace('0.1', '1').replace('d8', 'b0')}`, // 简单的加深颜色逻辑
    cursor: 'pointer'
  }
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

.schedule-card {
  height: 100%;
  border-radius: 8px;
  border: none;
  transition: all 0.3s;
  display: flex;
  flex-direction: column;
}

.schedule-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.schedule-header {
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
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.schedule-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 20px;
}

.info-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
  margin-bottom: 16px;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 14px;
  color: #606266;
  overflow: hidden;
}

.info-item span {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
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

.action-area {
  margin-top: auto;
  padding-top: 12px;
  border-top: 1px dashed #ebeef5;
  text-align: right;
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
  min-height: 70px;
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
  padding: 8px;
  border-radius: 6px;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  transition: all 0.2s;
}

.course-block:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.course-name-mini {
  font-weight: 600;
  line-height: 1.2;
}

.course-loc-mini {
  font-size: 11px;
  opacity: 0.8;
}
</style>
