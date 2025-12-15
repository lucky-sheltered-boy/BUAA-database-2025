<template>
  <div class="dashboard">
    <el-row :gutter="20">
      <!-- 欢迎卡片 -->
      <el-col :span="24">
        <el-card class="welcome-card">
          <div class="welcome-content">
            <div>
              <h2>欢迎回来，{{ authStore.userName }}同学！</h2>
              <p>{{ authStore.userInfo.department_name }} · {{ getCurrentTime() }}</p>
            </div>
            <el-icon :size="60" color="#409EFF"><UserFilled /></el-icon>
          </div>
        </el-card>
      </el-col>

      <!-- 统计卡片 -->
      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon :size="40" color="#409EFF"><Reading /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ stats.totalCourses }}</div>
              <div class="stat-label">已选课程</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon :size="40" color="#67C23A"><TrophyBase /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ stats.totalCredits }}</div>
              <div class="stat-label">总学分</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
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

      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon :size="40" color="#F56C6C"><Clock /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ stats.availableCourses }}</div>
              <div class="stat-label">可选课程</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 快捷操作 -->
      <el-col :span="24">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>快捷操作</span>
            </div>
          </template>
          <div class="quick-actions">
            <el-button type="primary" size="large" @click="router.push('/student/courses')">
              <el-icon><Reading /></el-icon>
              选课中心
            </el-button>
            <el-button type="success" size="large" @click="router.push('/student/schedule')">
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
import {
  UserFilled, Reading, TrophyBase, Calendar, Clock
} from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()
const semesterStore = useSemesterStore()

const stats = ref({
  totalCourses: 0,
  totalCredits: 0,
  weeklyClasses: 0,
  availableCourses: 0
})

const getCurrentTime = () => {
  const now = new Date()
  const hour = now.getHours()
  if (hour < 12) return '上午好'
  if (hour < 18) return '下午好'
  return '晚上好'
}

const fetchStats = async () => {
  try {
    // 获取已选课程
    const scheduleRes = await request.get(
      `/students/${authStore.userId}/schedule?semester_id=${semesterStore.currentSemesterId}`
    )
    if (scheduleRes.success) {
      const courses = scheduleRes.data || []
      
      // 按开课实例ID去重统计课程数（一门课可能有多个上课时间）
      const uniqueCourses = new Map()
      courses.forEach(course => {
        // 使用开课实例ID作为唯一标识
        const key = course.instance_id || course.course_id
        if (!uniqueCourses.has(key)) {
          uniqueCourses.set(key, course.credit)
        }
      })
      
      // 已选课程数 = 唯一开课实例数
      stats.value.totalCourses = uniqueCourses.size
      
      // 计算总学分
      stats.value.totalCredits = Array.from(uniqueCourses.values())
        .reduce((sum, credit) => sum + credit, 0)
      
      // 统计本周课程数
      const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']
      const today = weekdays[new Date().getDay()]
      stats.value.weeklyClasses = courses.filter(c => c.weekday === today).length
    }

    // 获取可选课程
    const availableRes = await request.get(`/students/${authStore.userId}/available-courses`)
    if (availableRes.success) {
      stats.value.availableCourses = availableRes.data?.length || 0
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

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.quick-actions {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
}
</style>
