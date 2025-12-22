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
  padding-bottom: 24px;
}

.el-row {
  margin-bottom: 24px;
}

.el-row:last-child {
  margin-bottom: 0;
}

.welcome-card {
  background: linear-gradient(to right, rgba(255, 255, 255, 0.95) 40%, rgba(255, 247, 230, 0.6) 100%), url('../../assets/images/VCG211461633966.webp') center/cover no-repeat;
  border: 1px solid #fff1b8;
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
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.primary-bg { background: #e6f7ff; color: #1890ff; }
.success-bg { background: #f6ffed; color: #52c41a; }
.warning-bg { background: #fff7e6; color: #faad14; }
.danger-bg { background: #fff1f0; color: #f5222d; }

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: #1f1f1f;
  line-height: 1.2;
  margin-bottom: 4px;
  font-family: 'Segoe UI', Roboto, sans-serif;
}

.stat-label {
  font-size: 14px;
  color: #8c8c8c;
  font-weight: 500;
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
  background: #faad14;
  border-radius: 2px;
}

/* User Stats */
.user-stat-item {
  display: flex;
  align-items: center;
  padding: 24px;
  background: #fafafa;
  border-radius: 16px;
  position: relative;
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid #f0f0f0;
}

.user-stat-item:hover {
  background: #fff;
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.06);
}

.user-icon-wrapper {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.user-info-wrapper {
  flex: 1;
}

.user-info-wrapper .count {
  font-size: 28px;
  font-weight: 700;
  color: #1f1f1f;
  line-height: 1.2;
}

.user-info-wrapper .role-label {
  font-size: 14px;
  color: #8c8c8c;
  margin-top: 4px;
  font-weight: 500;
}

.stat-bar {
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 4px;
  opacity: 0.8;
}

/* Quick Actions */
.quick-actions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
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

.action-btn.primary:hover { border-color: #e6f7ff; }
.action-btn.success:hover { border-color: #f6ffed; }
.action-btn.warning:hover { border-color: #fff7e6; }

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

.action-btn.primary .action-icon { background: #e6f7ff; color: #1890ff; }
.action-btn.success .action-icon { background: #f6ffed; color: #52c41a; }
.action-btn.warning .action-icon { background: #fff7e6; color: #faad14; }

.action-btn:hover .action-icon {
  transform: scale(1.1);
}

.action-text {
  flex: 1;
}

.action-text h3 {
  font-size: 17px;
  font-weight: 600;
  color: #1f1f1f;
  margin-bottom: 6px;
}

.action-text p {
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
