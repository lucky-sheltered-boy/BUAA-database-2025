<template>
  <div class="dashboard">
    <el-row :gutter="24">
      <el-col :span="24">
        <el-card class="welcome-card" shadow="hover">
          <div class="welcome-content">
            <div class="welcome-text">
              <h2>系统概览</h2>
              <p class="welcome-subtitle">
                <el-icon><OfficeBuilding /></el-icon> {{ authStore.userInfo.department_name }}
                <span class="separator">|</span>
                <el-icon><Management /></el-icon> 教务管理中心
              </p>
            </div>
            <div class="welcome-icon">
              <el-icon :size="64" color="var(--warning-color)"><DataAnalysis /></el-icon>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 统计卡片 -->
      <el-col :xs="24" :sm="12" :md="6" v-for="(item, key) in statsCards" :key="key">
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <div class="stat-icon" :class="item.bgClass">
              <el-icon><component :is="item.icon" /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ overview[key] || 0 }}</div>
              <div class="stat-label">{{ item.label }}</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 用户统计 -->
      <el-col :span="24">
        <el-card class="user-stat-card" shadow="hover">
          <template #header>
            <div class="card-header">
              <span class="header-title">用户分布统计</span>
            </div>
          </template>
          <el-row :gutter="24">
            <el-col :xs="24" :sm="8" v-for="(count, role) in overview.users" :key="role">
              <div class="user-stat-item">
                <div class="user-icon-wrapper">
                  <el-icon :size="32" :color="getUserRoleColor(role)">
                    <component :is="getUserRoleIcon(role)" />
                  </el-icon>
                </div>
                <div class="user-info-wrapper">
                  <div class="count">{{ count }}</div>
                  <div class="role-label">{{ role }}</div>
                </div>
                <div class="stat-bar" :style="{ background: getUserRoleColor(role) }"></div>
              </div>
            </el-col>
          </el-row>
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
            <div class="action-btn warning" @click="router.push('/admin/statistics')">
              <div class="action-icon">
                <el-icon><TrendCharts /></el-icon>
              </div>
              <div class="action-text">
                <h3>选课统计</h3>
                <p>查看实时选课数据分析</p>
              </div>
              <el-icon class="arrow-icon"><ArrowRight /></el-icon>
            </div>
            
            <div class="action-btn primary" @click="router.push('/admin/users')">
              <div class="action-icon">
                <el-icon><User /></el-icon>
              </div>
              <div class="action-text">
                <h3>用户管理</h3>
                <p>管理师生账号信息</p>
              </div>
              <el-icon class="arrow-icon"><ArrowRight /></el-icon>
            </div>

            <div class="action-btn success" @click="router.push('/admin/instances')">
              <div class="action-icon">
                <el-icon><Calendar /></el-icon>
              </div>
              <div class="action-text">
                <h3>开课管理</h3>
                <p>管理学期课程安排</p>
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
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import request from '@/utils/request'
import {
  DataAnalysis, OfficeBuilding, Reading, House, Calendar,
  User, Avatar, Management, TrendCharts, ArrowRight
} from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()

const overview = ref({
  departments: 0,
  courses: 0,
  classrooms: 0,
  current_instances: 0,
  current_enrollments: 0,
  users: {}
})

const statsCards = {
  departments: { label: '院系数量', icon: OfficeBuilding, bgClass: 'primary-bg' },
  courses: { label: '课程总数', icon: Reading, bgClass: 'success-bg' },
  classrooms: { label: '教室总数', icon: House, bgClass: 'warning-bg' },
  current_instances: { label: '本学期开课', icon: Calendar, bgClass: 'danger-bg' }
}

const getUserRoleIcon = (role) => {
  const map = {
    '学生': User,
    '教师': Avatar,
    '教务': Management
  }
  return map[role] || User
}

const getUserRoleColor = (role) => {
  const map = {
    '学生': '#409EFF',
    '教师': '#67C23A',
    '教务': '#E6A23C'
  }
  return map[role] || '#909399'
}

const fetchOverview = async () => {
  try {
    const res = await request.get('/statistics/overview')
    // request 已返回 data
    if (res) {
      overview.value = res
    }
  } catch (error) {
    console.error('获取概览失败:', error)
  }
}

onMounted(() => {
  fetchOverview()
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
  background: linear-gradient(135deg, #fff 0%, #fdf6ec 100%);
  border: none;
}

.welcome-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
}

.welcome-text h2 {
  font-size: 24px;
  color: var(--text-primary);
  margin-bottom: 12px;
  font-weight: 600;
}

.welcome-subtitle {
  display: flex;
  align-items: center;
  color: var(--text-secondary);
  font-size: 14px;
}

.welcome-subtitle .el-icon {
  margin-right: 4px;
}

.separator {
  margin: 0 12px;
  color: var(--border-color-light);
}

.stat-card {
  height: 100%;
  transition: all 0.3s;
  border: none;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--box-shadow-light);
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 20px;
}

.stat-icon {
  width: 56px;
  height: 56px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
}

.primary-bg { background: rgba(64, 158, 255, 0.1); color: var(--primary-color); }
.success-bg { background: rgba(103, 194, 58, 0.1); color: var(--success-color); }
.warning-bg { background: rgba(230, 162, 60, 0.1); color: var(--warning-color); }
.danger-bg { background: rgba(245, 108, 108, 0.1); color: var(--danger-color); }

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.2;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 13px;
  color: var(--text-secondary);
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
}

/* User Stats */
.user-stat-item {
  display: flex;
  align-items: center;
  padding: 20px;
  background: #f9fafc;
  border-radius: 8px;
  position: relative;
  overflow: hidden;
  transition: all 0.3s;
}

.user-stat-item:hover {
  background: #fff;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.user-icon-wrapper {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.user-info-wrapper {
  flex: 1;
}

.user-info-wrapper .count {
  font-size: 24px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.2;
}

.user-info-wrapper .role-label {
  font-size: 13px;
  color: var(--text-secondary);
  margin-top: 4px;
}

.stat-bar {
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 3px;
  opacity: 0.5;
}

/* Quick Actions */
.quick-actions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 20px;
}

.action-btn {
  display: flex;
  align-items: center;
  padding: 24px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s;
  border: 1px solid var(--border-color-light);
  background: #fff;
}

.action-btn:hover {
  transform: translateY(-2px);
  box-shadow: var(--box-shadow-light);
}

.action-btn.primary:hover { border-color: var(--primary-color); }
.action-btn.success:hover { border-color: var(--success-color); }
.action-btn.warning:hover { border-color: var(--warning-color); }

.action-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  margin-right: 16px;
}

.action-btn.primary .action-icon { background: rgba(64, 158, 255, 0.1); color: var(--primary-color); }
.action-btn.success .action-icon { background: rgba(103, 194, 58, 0.1); color: var(--success-color); }
.action-btn.warning .action-icon { background: rgba(230, 162, 60, 0.1); color: var(--warning-color); }

.action-text {
  flex: 1;
}

.action-text h3 {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 4px;
}

.action-text p {
  font-size: 13px;
  color: var(--text-secondary);
}

.arrow-icon {
  color: var(--text-placeholder);
  transition: transform 0.3s;
}

.action-btn:hover .arrow-icon {
  transform: translateX(4px);
  color: var(--text-secondary);
}
</style>
