<template>
  <div class="my-schedule">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>我的授课安排</span>
          <el-button @click="fetchSchedule" :loading="loading">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </template>

      <div v-loading="loading">
        <el-empty v-if="!loading && scheduleData.length === 0" description="暂无授课安排" />

        <div v-else>
          <!-- 课程列表 -->
          <el-row :gutter="20">
            <el-col 
              v-for="course in groupedCourses" 
              :key="course.course_id"
              :xs="24" :sm="12" :md="8"
            >
              <el-card class="course-card" shadow="hover">
                <div class="course-header">
                  <h3>{{ course.course_name }}</h3>
                  <el-tag type="success">{{ course.course_id }}</el-tag>
                </div>

                <div class="course-stats">
                  <div class="stat-item">
                    <span class="label">已选人数:</span>
                    <span class="value">{{ course.enrolled_students }}</span>
                  </div>
                  <div class="stat-item">
                    <span class="label">总名额:</span>
                    <span class="value">{{ course.total_quota }}</span>
                  </div>
                  <div class="stat-item">
                    <span class="label">选课率:</span>
                    <el-progress 
                      :percentage="Math.round((course.enrolled_students / course.total_quota) * 100)"
                      :color="getProgressColor(course.enrolled_students / course.total_quota)"
                    />
                  </div>
                </div>

                <el-divider />

                <div class="time-info">
                  <div class="info-item">
                    <el-icon><Location /></el-icon>
                    <span>{{ course.building }} {{ course.room }}</span>
                  </div>
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
                  type="primary"
                  plain
                  size="small"
                  class="view-students-btn"
                  @click="viewStudents(course)"
                >
                  <el-icon><User /></el-icon>
                  查看学生名单
                </el-button>
              </el-card>
            </el-col>
          </el-row>
        </div>
      </div>
    </el-card>

    <!-- 学生名单对话框 -->
    <el-dialog 
      v-model="studentDialogVisible" 
      :title="`《${selectedCourse?.course_name}》学生名单`"
      width="70%"
    >
      <el-table :data="students" v-loading="studentsLoading">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="student_number" label="学号" width="120" />
        <el-table-column prop="name" label="姓名" width="100" />
        <el-table-column prop="department" label="院系" />
        <el-table-column prop="enroll_type" label="选课类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.enroll_type === '本院系' ? 'success' : 'warning'" size="small">
              {{ row.enroll_type }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="enroll_time" label="选课时间" width="180" />
      </el-table>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { useSemesterStore } from '@/stores/semester'
import request from '@/utils/request'
import { Refresh, Location, User } from '@element-plus/icons-vue'

const authStore = useAuthStore()
const semesterStore = useSemesterStore()

const loading = ref(false)
const scheduleData = ref([])
const studentDialogVisible = ref(false)
const studentsLoading = ref(false)
const students = ref([])
const selectedCourse = ref(null)

// 按课程分组
const groupedCourses = computed(() => {
  const courseMap = new Map()
  
  scheduleData.value.forEach(item => {
    const key = item.course_id
    if (!courseMap.has(key)) {
      courseMap.set(key, {
        ...item,
        timeSlots: [],
        instance_id: null // 需要从某处获取
      })
    }
    
    courseMap.get(key).timeSlots.push({
      weekday: item.weekday,
      start_time: item.start_time,
      end_time: item.end_time,
      week_range: item.week_range,
      week_type: item.week_type
    })
  })
  
  return Array.from(courseMap.values())
})

const getProgressColor = (rate) => {
  if (rate < 0.5) return '#67C23A'
  if (rate < 0.8) return '#E6A23C'
  return '#F56C6C'
}

const fetchSchedule = async () => {
  loading.value = true
  try {
    const res = await request.get(
      `/teachers/${authStore.userId}/schedule?semester_id=${semesterStore.currentSemesterId}`
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

const viewStudents = async (course) => {
  selectedCourse.value = course
  studentDialogVisible.value = true
  studentsLoading.value = true
  
  try {
    // 注意：这里需要instance_id，实际应该从后端返回
    // 暂时使用course_id作为替代（需要修改后端或前端逻辑）
    ElMessage.warning('查看学生名单功能需要开课实例ID，请确保后端返回该字段')
    students.value = []
  } catch (error) {
    ElMessage.error('获取学生名单失败')
  } finally {
    studentsLoading.value = false
  }
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

.course-card {
  margin-bottom: 20px;
  transition: all 0.3s;
}

.course-card:hover {
  transform: translateY(-2px);
}

.course-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
}

.course-header h3 {
  margin: 0;
  font-size: 16px;
  color: #303133;
  flex: 1;
}

.course-stats {
  margin-bottom: 15px;
}

.stat-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
  font-size: 13px;
}

.stat-item .label {
  color: #909399;
}

.stat-item .value {
  color: #303133;
  font-weight: 600;
}

.time-info {
  margin: 15px 0;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
  font-size: 13px;
  color: #606266;
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

.view-students-btn {
  width: 100%;
  margin-top: 10px;
}
</style>
