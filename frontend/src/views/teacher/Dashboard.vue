<template>
  <div class="dashboard">
    <el-row :gutter="24">
      <el-col :span="24">
        <el-card class="welcome-card" shadow="hover">
          <div class="welcome-content">
            <div class="welcome-text">
              <h2>欢迎您，{{ authStore.userName }}老师！</h2>
              <p class="welcome-subtitle">
                <el-icon><OfficeBuilding /></el-icon> {{ authStore.userInfo.department_name }}
                <span class="separator">|</span>
                <el-icon><Timer /></el-icon> {{ getCurrentTime() }}
              </p>
            </div>
            <div class="welcome-icon">
              <el-icon :size="64" color="var(--success-color)"><Avatar /></el-icon>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="8">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <div class="stat-icon success-bg">
              <el-icon><Reading /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.totalCourses }}</div>
              <div class="stat-label">在开课程</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="8">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <div class="stat-icon primary-bg">
              <el-icon><User /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.totalStudents }}</div>
              <div class="stat-label">学生总数</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="8">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <div class="stat-icon warning-bg">
              <el-icon><DataLine /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.avgEnrollment }}%</div>
              <div class="stat-label">平均选课率</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="24" class="mt-4">
      <el-col :span="24">
        <el-card class="chart-card" shadow="hover">
          <template #header>
            <div class="card-header">
              <span class="header-title">课程选课情况</span>
              <el-button text type="primary" @click="router.push('/teacher/schedule')">
                查看详情 <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
          </template>
          <div class="course-list">
            <el-table :data="courseStats" style="width: 100%" :show-header="true">
              <el-table-column prop="course_name" label="课程名称" min-width="180" />
              <el-table-column prop="course_id" label="课程代码" width="120" />
              <el-table-column label="选课人数" width="200">
                <template #default="{ row }">
                  <div class="progress-cell">
                    <el-progress 
                      :percentage="Math.min((row.enrolled / row.quota) * 100, 100)"
                      :status="getProgressStatus(row)"
                      :stroke-width="8"
                    >
                      <template #default>
                        <span class="progress-text">{{ row.enrolled }}/{{ row.quota }}</span>
                      </template>
                    </el-progress>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="状态" width="100">
                <template #default="{ row }">
                  <el-tag :type="getStatusType(row)" size="small" effect="plain">
                    {{ getStatusText(row) }}
                  </el-tag>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useSemesterStore } from '@/stores/semester'
import request from '@/utils/request'
import { 
  OfficeBuilding, Timer, Avatar, Reading, 
  User, DataLine, ArrowRight 
} from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()
const semesterStore = useSemesterStore()

const stats = ref({
  totalCourses: 0,
  totalStudents: 0,
  avgEnrollment: 0
})

const courseStats = ref([])

const getCurrentTime = () => {
  const now = new Date()
  const hours = now.getHours()
  let timeText = ''
  if (hours < 12) timeText = '上午好'
  else if (hours < 18) timeText = '下午好'
  else timeText = '晚上好'
  return `${timeText}，今天是 ${now.toLocaleDateString()}`
}

const fetchStats = async () => {
  try {
    const res = await request.get(`/teachers/${authStore.userId}/schedule`, { 
      params: { semester_id: semesterStore.currentSemesterId } 
    })
    const list = Array.isArray(res) ? res : []
    
    // 1. 按开课实例去重 (因为一个实例可能有多个上课时间段，会返回多条记录)
    const uniqueInstancesMap = new Map()
    list.forEach(item => {
      if (!uniqueInstancesMap.has(item.instance_id)) {
        uniqueInstancesMap.set(item.instance_id, item)
      }
    })
    const uniqueInstances = Array.from(uniqueInstancesMap.values())

    // 2. 按课程ID去重统计课程数
    const uniqueCourseIds = new Set(uniqueInstances.map(c => c.course_id))
    stats.value.totalCourses = uniqueCourseIds.size

    // 3. 统计学生总数 (累加所有去重后的实例的选课人数)
    stats.value.totalStudents = uniqueInstances.reduce((sum, c) => sum + (c.enrolled_students || 0), 0)
    
    const totalQuota = uniqueInstances.reduce((sum, c) => sum + (c.total_quota || 0), 0)
    stats.value.avgEnrollment = totalQuota > 0 
      ? Math.round((stats.value.totalStudents / totalQuota) * 100) 
      : 0

    // 4. 课程列表数据 (按课程聚合)
    const courseMap = new Map()
    uniqueInstances.forEach(c => {
      if (!courseMap.has(c.course_id)) {
        courseMap.set(c.course_id, {
          course_name: c.course_name,
          course_id: c.course_id,
          enrolled: 0,
          quota: 0
        })
      }
      const course = courseMap.get(c.course_id)
      course.enrolled += (c.enrolled_students || 0)
      course.quota += (c.total_quota || 0)
    })
    
    courseStats.value = Array.from(courseMap.values())
  } catch (error) {
    console.error('获取统计数据失败:', error)
  }
}

const getProgressStatus = (row) => {
  const percentage = row.enrolled / row.quota
  if (percentage >= 1) return 'exception'
  if (percentage >= 0.8) return 'warning'
  return 'success'
}

const getStatusType = (row) => {
  const percentage = row.enrolled / row.quota
  if (percentage >= 1) return 'danger'
  if (percentage >= 0.8) return 'warning'
  return 'success'
}

const getStatusText = (row) => {
  const percentage = row.enrolled / row.quota
  if (percentage >= 1) return '已满'
  if (percentage >= 0.8) return '拥挤'
  return '正常'
}

onMounted(() => {
  fetchStats()
})
</script>

<style scoped>
.dashboard {
  padding-bottom: 20px;
}

.welcome-card {
  background: linear-gradient(135deg, #f0f9eb 0%, #ffffff 100%);
  border: none;
  margin-bottom: 24px;
}

.welcome-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 20px;
}

.welcome-text h2 {
  margin: 0 0 12px 0;
  font-size: 24px;
  color: #303133;
}

.welcome-subtitle {
  margin: 0;
  color: #606266;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.separator {
  color: #dcdfe6;
  margin: 0 8px;
}

.stat-card {
  margin-bottom: 24px;
  border: none;
  transition: all 0.3s;
}

.stat-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 10px;
}

.stat-icon {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
}

.success-bg {
  background-color: #f0f9eb;
  color: var(--success-color);
}

.primary-bg {
  background-color: #ecf5ff;
  color: var(--primary-color);
}

.warning-bg {
  background-color: #fdf6ec;
  color: var(--warning-color);
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
  line-height: 1.2;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 13px;
  color: #909399;
}

.mt-4 {
  margin-top: 24px;
}

.chart-card {
  border: none;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.progress-cell {
  padding-right: 20px;
}

.progress-text {
  font-size: 12px;
  color: #606266;
  margin-left: 8px;
}
</style>
