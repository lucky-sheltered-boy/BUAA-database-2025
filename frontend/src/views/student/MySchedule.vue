<template>
  <div class="my-schedule">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>我的课表</span>
          <div class="header-actions">
            <el-button @click="fetchSchedule" :loading="loading">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
          </div>
        </div>
      </template>

      <div v-loading="loading">
        <!-- 课程列表视图 -->
        <div class="course-list" v-if="scheduleData.length > 0">
          <el-row :gutter="20">
            <el-col 
              v-for="(course, index) in groupedCourses" 
              :key="index"
              :xs="24" :sm="12" :md="8"
            >
              <el-card class="schedule-card" shadow="hover">
                <div class="schedule-header">
                  <h3>{{ course.course_name }}</h3>
                  <el-tag type="success">{{ course.credit }}学分</el-tag>
                </div>

                <div class="schedule-info">
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
                    <span>{{ course.building }} {{ course.room }}</span>
                  </div>
                </div>

                <el-divider />

                <div class="time-slots">
                  <div 
                    v-for="(slot, idx) in course.timeSlots" 
                    :key="idx"
                    class="time-slot"
                  >
                    <el-tag size="small">{{ slot.weekday }}</el-tag>
                    <span>{{ slot.start_time }}-{{ slot.end_time }}</span>
                    <span class="week-range">{{ slot.week_range }} {{ slot.week_type }}</span>
                  </div>
                </div>

                <el-button 
                  type="danger" 
                  plain
                  size="small"
                  class="drop-btn"
                  @click="handleDrop(course)"
                >
                  <el-icon><Delete /></el-icon>
                  退课
                </el-button>
              </el-card>
            </el-col>
          </el-row>
        </div>

        <!-- 课表格视图 -->
        <div class="schedule-table-view" v-if="scheduleData.length > 0">
          <el-divider>课表格式</el-divider>
          <table class="schedule-table">
            <thead>
              <tr>
                <th>时间</th>
                <th v-for="day in weekdays" :key="day">{{ day }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="slot in timeSlots" :key="slot.value">
                <td class="time-cell">
                  <div>{{ slot.label }}</div>
                  <div class="time-range">{{ slot.time }}</div>
                </td>
                <td 
                  v-for="day in weekdays" 
                  :key="day"
                  class="course-cell"
                >
                  <div 
                    v-for="course in getCourseAtTime(day, slot.value)"
                    :key="course.course_id"
                    class="course-block"
                  >
                    <div class="course-name">{{ course.course_name }}</div>
                    <div class="course-detail">{{ course.building }} {{ course.room }}</div>
                    <div class="course-teacher">{{ course.teacher_name }}</div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <el-empty v-if="!loading && scheduleData.length === 0" description="暂无课程安排" />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { useSemesterStore } from '@/stores/semester'
import request from '@/utils/request'
import { TIME_SLOTS } from '@/utils/constants'
import { Refresh, Reading, User, Location, Delete } from '@element-plus/icons-vue'

const authStore = useAuthStore()
const semesterStore = useSemesterStore()

const loading = ref(false)
const scheduleData = ref([])

const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五']
const timeSlots = TIME_SLOTS

// 按课程分组
const groupedCourses = computed(() => {
  const courseMap = new Map()
  
  scheduleData.value.forEach(item => {
    if (!courseMap.has(item.course_id)) {
      courseMap.set(item.course_id, {
        ...item,
        timeSlots: []
      })
    }
    
    courseMap.get(item.course_id).timeSlots.push({
      weekday: item.weekday,
      start_time: item.start_time,
      end_time: item.end_time,
      week_range: item.week_range,
      week_type: item.week_type
    })
  })
  
  return Array.from(courseMap.values())
})

// 获取特定时间的课程
const getCourseAtTime = (weekday, timeSlot) => {
  return scheduleData.value.filter(course => {
    if (course.weekday !== weekday) return false
    
    // 简单的时间匹配（实际应该根据start_time和end_time精确匹配）
    const slot = TIME_SLOTS.find(s => s.value === timeSlot)
    if (!slot) return false
    
    return course.start_time.includes(slot.time.split('-')[0].substring(0, 2))
  })
}

const fetchSchedule = async () => {
  loading.value = true
  try {
    const res = await request.get(
      `/students/${authStore.userId}/schedule?semester_id=${semesterStore.currentSemesterId}`
    )
    
    if (res.success) {
      scheduleData.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取课表失败')
  } finally {
    loading.value = false
  }
}

const handleDrop = (course) => {
  ElMessageBox.confirm(
    `确定要退选《${course.course_name}》吗？退课后可能无法再次选上。`,
    '退课确认',
    {
      confirmButtonText: '确定退课',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(async () => {
    try {
      // 使用course中的instance_id进行退课
      const res = await request.post(
        `/students/${authStore.userId}/drop`,
        { instance_id: course.instance_id }
      )
      
      if (res.success) {
        ElMessage.success(res.message || '退课成功')
        // 重新加载课表
        await fetchSchedule()
      }
    } catch (error) {
      ElMessage.error(error.response?.data?.message || '退课失败')
    }
  }).catch(() => {
    // 用户取消
  })
}

onMounted(() => {
  fetchSchedule()
})
</script>

<style scoped>
.my-schedule {
  max-width: 1400px;
  margin: 0 auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.course-list {
  margin-bottom: 30px;
}

.schedule-card {
  margin-bottom: 20px;
  transition: all 0.3s;
}

.schedule-card:hover {
  transform: translateY(-2px);
}

.schedule-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
}

.schedule-header h3 {
  margin: 0;
  font-size: 16px;
  color: #303133;
  flex: 1;
}

.schedule-info {
  margin-bottom: 15px;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  font-size: 13px;
  color: #606266;
}

.time-slots {
  margin: 15px 0;
}

.time-slot {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
  font-size: 13px;
  color: #606266;
}

.week-range {
  color: #909399;
  font-size: 12px;
}

.drop-btn {
  width: 100%;
  margin-top: 10px;
}

.schedule-table-view {
  margin-top: 30px;
  overflow-x: auto;
}

.schedule-table {
  width: 100%;
  border-collapse: collapse;
  background: white;
}

.schedule-table th,
.schedule-table td {
  border: 1px solid #ebeef5;
  padding: 12px 8px;
  text-align: center;
}

.schedule-table th {
  background: #f5f7fa;
  color: #606266;
  font-weight: 600;
}

.time-cell {
  background: #fafafa;
  min-width: 100px;
}

.time-range {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}

.course-cell {
  min-width: 120px;
  vertical-align: top;
}

.course-block {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 10px;
  border-radius: 6px;
  margin: 4px;
  font-size: 12px;
}

.course-name {
  font-weight: 600;
  margin-bottom: 4px;
}

.course-detail,
.course-teacher {
  font-size: 11px;
  opacity: 0.9;
}
</style>
