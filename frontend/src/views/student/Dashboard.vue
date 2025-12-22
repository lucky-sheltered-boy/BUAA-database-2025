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
  padding-bottom: 24px;
}

.el-row {
  margin-bottom: 24px;
}

.el-row:last-child {
  margin-bottom: 0;
}

.welcome-card {
  background: linear-gradient(to right, rgba(255, 255, 255, 0.95) 40%, rgba(240, 247, 255, 0.6) 100%), url('../../assets/images/VCG211399110988.webp') center/cover no-repeat;
  border: 1px solid #e6f7ff;
  position: relative;
  overflow: hidden;
}

.welcome-card::after {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  width: 200px;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.5));
  transform: skewX(-20deg);
}

.welcome-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  position: relative;
  z-index: 1;
}

.welcome-text h2 {
  margin: 0 0 12px 0;
  font-size: 26px;
  color: #1f1f1f;
  font-weight: 600;
}

.welcome-subtitle {
  margin: 0;
  color: #606266;
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 15px;
}

.separator {
  color: #dcdfe6;
  margin: 0 4px;
}

.stat-card {
  border: none;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08) !important;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 24px;
  padding: 8px;
}

.stat-icon {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  color: #fff;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.primary-bg { background: linear-gradient(135deg, #1890ff 0%, #69c0ff 100%); }
.success-bg { background: linear-gradient(135deg, #52c41a 0%, #95de64 100%); }
.warning-bg { background: linear-gradient(135deg, #faad14 0%, #ffc53d 100%); }
.danger-bg { background: linear-gradient(135deg, #f5222d 0%, #ff7875 100%); }

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: #1f1f1f;
  line-height: 1.2;
  margin-bottom: 4px;
  font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
}

.stat-label {
  font-size: 14px;
  color: #8c8c8c;
  font-weight: 500;
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
  font-weight: 600;
  color: #1f1f1f;
  display: flex;
  align-items: center;
  gap: 8px;
}

.header-title::before {
  content: '';
  display: block;
  width: 4px;
  height: 18px;
  background: #1890ff;
  border-radius: 2px;
}

.quick-actions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 24px;
  padding: 8px 0;
}

.action-btn {
  display: flex;
  align-items: center;
  padding: 24px;
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid #f0f0f0;
  background: #fafafa;
}

.action-btn:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.06);
  background: #fff;
}

.action-btn.primary:hover {
  border-color: #e6f7ff;
}

.action-btn.success:hover {
  border-color: #f6ffed;
}

.action-icon {
  width: 56px;
  height: 56px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  margin-right: 20px;
  transition: all 0.3s ease;
}

.action-btn.primary .action-icon {
  background-color: #e6f7ff;
  color: #1890ff;
}

.action-btn.success .action-icon {
  background-color: #f6ffed;
  color: #52c41a;
}

.action-btn:hover .action-icon {
  transform: scale(1.1);
}

.action-text {
  flex: 1;
}

.action-text h3 {
  margin: 0 0 6px 0;
  font-size: 17px;
  color: #1f1f1f;
  font-weight: 600;
}

.action-text p {
  margin: 0;
  font-size: 14px;
  color: #8c8c8c;
}

.arrow-icon {
  color: #d9d9d9;
  font-size: 20px;
  transition: transform 0.3s ease;
}

.action-btn:hover .arrow-icon {
  transform: translateX(4px);
  color: #1890ff;
}
</style>
