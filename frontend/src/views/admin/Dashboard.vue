<template>
  <div class="dashboard">
    <el-row :gutter="20">
      <el-col :span="24">
        <el-card class="welcome-card">
          <div class="welcome-content">
            <div>
              <h2>系统概览</h2>
              <p>{{ authStore.userInfo.department_name }} · 教务管理</p>
            </div>
            <el-icon :size="60" color="#E6A23C"><DataAnalysis /></el-icon>
          </div>
        </el-card>
      </el-col>

      <!-- 统计卡片 -->
      <el-col :xs="24" :sm="12" :md="6" v-for="(item, key) in statsCards" :key="key">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon :size="40" :color="item.color">
              <component :is="item.icon" />
            </el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ overview[key] || 0 }}</div>
              <div class="stat-label">{{ item.label }}</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 用户统计 -->
      <el-col :span="24">
        <el-card>
          <template #header>
            <span>用户统计</span>
          </template>
          <el-row :gutter="20">
            <el-col :xs="24" :sm="8" v-for="(count, role) in overview.users" :key="role">
              <div class="user-stat">
                <div class="user-icon">
                  <el-icon :size="30" :color="getUserRoleColor(role)">
                    <component :is="getUserRoleIcon(role)" />
                  </el-icon>
                </div>
                <div class="user-info">
                  <div class="count">{{ count }}</div>
                  <div class="role">{{ role }}</div>
                </div>
              </div>
            </el-col>
          </el-row>
        </el-card>
      </el-col>

      <!-- 快捷操作 -->
      <el-col :span="24">
        <el-card>
          <template #header>
            <span>快捷操作</span>
          </template>
          <div class="quick-actions">
            <el-button type="warning" size="large" @click="router.push('/admin/statistics')">
              <el-icon><TrendCharts /></el-icon>
              选课统计
            </el-button>
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
  User, Avatar, Management, TrendCharts
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
  departments: { label: '院系数量', icon: OfficeBuilding, color: '#409EFF' },
  courses: { label: '课程总数', icon: Reading, color: '#67C23A' },
  classrooms: { label: '教室总数', icon: House, color: '#E6A23C' },
  current_instances: { label: '本学期开课', icon: Calendar, color: '#F56C6C' }
}

const getUserRoleColor = (role) => {
  const colors = {
    '学生': '#409EFF',
    '教师': '#67C23A',
    '教务': '#E6A23C'
  }
  return colors[role] || '#909399'
}

const getUserRoleIcon = (role) => {
  const icons = {
    '学生': User,
    '教师': Avatar,
    '教务': Management
  }
  return icons[role] || User
}

const fetchOverview = async () => {
  try {
    const res = await request.get('/statistics/overview')
    if (res.success) {
      overview.value = res.data || {}
    }
  } catch (error) {
    ElMessage.error('获取系统概览失败')
  }
}

onMounted(() => {
  fetchOverview()
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

.user-stat {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 20px;
  background: #f5f7fa;
  border-radius: 8px;
  margin-bottom: 20px;
}

.user-icon {
  width: 50px;
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
  border-radius: 50%;
}

.user-info .count {
  font-size: 24px;
  font-weight: bold;
  color: #303133;
  line-height: 1;
  margin-bottom: 5px;
}

.user-info .role {
  font-size: 14px;
  color: #909399;
}

.quick-actions {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
}
</style>
