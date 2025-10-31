<template>
  <div class="dashboard">
    <el-row :gutter="20">
      <el-col :span="24">
        <el-card class="welcome-card">
          <div class="welcome-content">
            <div>
              <h2>欢迎，{{ authStore.userName }}老师！</h2>
              <p>{{ authStore.userInfo.department_name }} · {{ getCurrentTime() }}</p>
            </div>
            <el-icon :size="60" color="#67C23A"><Avatar /></el-icon>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon :size="40" color="#67C23A"><Reading /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ stats.totalCourses }}</div>
              <div class="stat-label">授课门数</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon :size="40" color="#409EFF"><User /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ stats.totalStudents }}</div>
              <div class="stat-label">学生总数</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon :size="40" color="#E6A23C"><Calendar /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ stats.weeklyClasses }}</div>
              <div class="stat-label">本周课程</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :span="24">
        <el-card>
          <template #header>
            <span>快捷操作</span>
          </template>
          <div class="quick-actions">
            <el-button type="success" size="large" @click="router.push('/teacher/schedule')">
              <el-icon><Calendar /></el-icon>
              查看课表
            </el-button>
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
import { Avatar, Reading, User, Calendar } from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()
const semesterStore = useSemesterStore()

const stats = ref({
  totalCourses: 0,
  totalStudents: 0,
  weeklyClasses: 0
})

const getCurrentTime = () => {
  const hour = new Date().getHours()
  if (hour < 12) return '上午好'
  if (hour < 18) return '下午好'
  return '晚上好'
}

const fetchStats = async () => {
  try {
    const res = await request.get(
      `/teachers/${authStore.userId}/schedule?semester_id=${semesterStore.currentSemesterId}`
    )
    
    if (res.success) {
      const schedule = res.data || []
      // 统计课程数（去重）
      const uniqueCourses = new Set(schedule.map(s => s.course_id))
      stats.value.totalCourses = uniqueCourses.size
      
      // 统计学生总数
      stats.value.totalStudents = schedule.reduce((sum, s) => sum + (s.enrolled_students || 0), 0)
      
      // 统计本周课程
      const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']
      const today = weekdays[new Date().getDay()]
      stats.value.weeklyClasses = schedule.filter(s => s.weekday === today).length
    }
  } catch (error) {
    console.error('获取统计数据失败:', error)
  }
}

onMounted(() => {
  fetchStats()
})
</script>

<style scoped>
.dashboard {
  max-width: 1400px;
  margin: 0 auto;
}

.welcome-card {
  margin-bottom: 20px;
}

.welcome-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.welcome-content h2 {
  font-size: 24px;
  color: #303133;
  margin: 0 0 10px 0;
}

.welcome-content p {
  font-size: 14px;
  color: #909399;
  margin: 0;
}

.stat-card {
  margin-bottom: 20px;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 15px;
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
  line-height: 1;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}

.quick-actions {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
}
</style>
