<template>
  <div class="dashboard">
    <el-row :gutter="24">
      <!-- 欢迎卡片 -->
      <el-col :span="24">
        <el-card class="welcome-card" shadow="hover">
          <div class="welcome-content">
            <div class="welcome-text">
              <h2>欢迎回来，{{ authStore.userName }}同学！</h2>
              <p class="welcome-subtitle">
                <el-icon><OfficeBuilding /></el-icon> {{ authStore.userInfo.department_name }}
                <span class="separator">|</span>
                <el-icon><Timer /></el-icon> {{ getCurrentTime() }}
              </p>
            </div>
            <div class="welcome-icon">
              <el-icon :size="64" color="var(--primary-color)"><UserFilled /></el-icon>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 统计卡片 -->
      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <div class="stat-icon primary-bg">
              <el-icon><Reading /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.totalCourses }}</div>
              <div class="stat-label">已选课程</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <div class="stat-icon success-bg">
              <el-icon><TrophyBase /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.totalCredits }}</div>
              <div class="stat-label">总学分</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <div class="stat-icon warning-bg">
              <el-icon><Calendar /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.weeklyClasses }}</div>
              <div class="stat-label">本周课程</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <div class="stat-icon danger-bg">
              <el-icon><Clock /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.availableCourses }}</div>
              <div class="stat-label">可选课程</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 快捷操作 -->
      <el-col :span="24">
        <el-card class="action-card" shadow="hover">
          <template #header>
            <div class="card-header">
              <span class="header-title">快捷操作</span>
            </div>
          </template>
          <div class="quick-actions">
            <div class="action-btn primary" @click="router.push('/student/courses')">
              <div class="action-icon">
                <el-icon><Reading /></el-icon>
              </div>
              <div class="action-text">
                <h3>选课中心</h3>
                <p>浏览并选择新课程</p>
              </div>
              <el-icon class="arrow-icon"><ArrowRight /></el-icon>
            </div>
            
            <div class="action-btn success" @click="router.push('/student/schedule')">
              <div class="action-icon">
                <el-icon><Calendar /></el-icon>
              </div>
              <div class="action-text">
                <h3>查看课表</h3>
                <p>查看本学期课程安排</p>
              </div>
              <el-icon class="arrow-icon"><ArrowRight /></el-icon>
            </div>
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
  UserFilled, Reading, TrophyBase, Calendar, Clock,
  OfficeBuilding, Timer, ArrowRight
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
  const hours = now.getHours()
  let timeText = ''
  if (hours < 6) timeText = '凌晨好'
  else if (hours < 9) timeText = '早上好'
  else if (hours < 12) timeText = '上午好'
  else if (hours < 14) timeText = '中午好'
  else if (hours < 17) timeText = '下午好'
  else if (hours < 19) timeText = '傍晚好'
  else timeText = '晚上好'
  
  return `${timeText}，今天也要加油哦！`
}

const fetchStats = async () => {
  try {
    // 获取已选课程
    const enrolledRes = await request.get(`/students/${authStore.userId}/schedule`, {
      params: { semester_id: semesterStore.currentSemesterId }
    })
    const enrolledCourses = enrolledRes || []
    stats.value.totalCourses = enrolledCourses.length
    stats.value.totalCredits = enrolledCourses.reduce((sum, course) => sum + (course.credits || 0), 0)
    
    // 估算周课时
    stats.value.weeklyClasses = enrolledCourses.length * 2 // 假设每门课每周2课时
    
    // 获取可选课程
    const availableRes = await request.get(`/students/${authStore.userId}/available-courses`)
    stats.value.availableCourses = (availableRes || []).length
  } catch (error) {
    console.error('获取统计信息失败:', error)
  }
}

onMounted(() => {
  fetchStats()
})
</script>

<style scoped>
.dashboard {
  padding-bottom: 20px;
}

.el-row {
  margin-bottom: 24px;
}

.el-row:last-child {
  margin-bottom: 0;
}

.welcome-card {
  background: linear-gradient(135deg, #fff 0%, #f0f7ff 100%);
  border: none;
}

.welcome-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
}

.welcome-text h2 {
  margin: 0 0 10px 0;
  font-size: 24px;
  color: #303133;
}

.welcome-subtitle {
  margin: 0;
  color: #606266;
  display: flex;
  align-items: center;
  gap: 8px;
}

.separator {
  color: #dcdfe6;
  margin: 0 8px;
}

.stat-card {
  border: none;
  transition: all 0.3s;
}

.stat-card:hover {
  transform: translateY(-5px);
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 20px;
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 30px;
  color: #fff;
}

.primary-bg { background: linear-gradient(135deg, #409eff 0%, #79bbff 100%); }
.success-bg { background: linear-gradient(135deg, #67c23a 0%, #95d475 100%); }
.warning-bg { background: linear-gradient(135deg, #e6a23c 0%, #f3d19e 100%); }
.danger-bg { background: linear-gradient(135deg, #f56c6c 0%, #fab6b6 100%); }

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
  line-height: 1.2;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-top: 4px;
}

.action-card {
  border: none;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-title {
  font-size: 18px;
  font-weight: bold;
  color: #303133;
}

.quick-actions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.action-btn {
  display: flex;
  align-items: center;
  padding: 20px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s;
  border: 1px solid #ebeef5;
}

.action-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.action-btn.primary:hover {
  border-color: #409eff;
  background-color: #ecf5ff;
}

.action-btn.success:hover {
  border-color: #67c23a;
  background-color: #f0f9eb;
}

.action-icon {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  margin-right: 16px;
}

.action-btn.primary .action-icon {
  background-color: #ecf5ff;
  color: #409eff;
}

.action-btn.success .action-icon {
  background-color: #f0f9eb;
  color: #67c23a;
}

.action-text {
  flex: 1;
}

.action-text h3 {
  margin: 0 0 4px 0;
  font-size: 16px;
  color: #303133;
}

.action-text p {
  margin: 0;
  font-size: 13px;
  color: #909399;
}

.arrow-icon {
  color: #c0c4cc;
  font-size: 20px;
}
</style>
