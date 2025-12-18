<template>
  <div class="layout-container">
    <!-- 顶部导航栏 -->
    <el-header class="header">
      <div class="header-left">
        <div class="logo-area">
          <el-icon :size="28" color="var(--warning-color)"><School /></el-icon>
          <span class="system-title">高校课程选课管理系统</span>
          <el-tag type="warning" size="small" effect="plain" class="role-tag">管理员</el-tag>
        </div>
      </div>
      
      <div class="header-right">
        <div class="action-items">
          <el-tooltip content="消息通知" placement="bottom">
            <div class="action-item">
              <el-badge is-dot class="notification-badge">
                <el-icon><Bell /></el-icon>
              </el-badge>
            </div>
          </el-tooltip>
        </div>

        <el-dropdown trigger="click" class="user-dropdown">
          <div class="user-info">
            <el-avatar :size="32" class="user-avatar">
              {{ authStore.userName.substring(0, 1) }}
            </el-avatar>
            <div class="user-details">
              <span class="username">{{ authStore.userName }}</span>
              <span class="user-id">{{ authStore.userInfo.username }}</span>
            </div>
            <el-icon class="dropdown-icon"><ArrowDown /></el-icon>
          </div>
          <template #dropdown>
            <el-dropdown-menu class="user-dropdown-menu">
              <div class="dropdown-header">
                <span class="department">{{ authStore.userInfo.department_name }}</span>
              </div>
              <el-dropdown-item divided @click="handleLogout">
                <el-icon><SwitchButton /></el-icon>
                退出登录
              </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </el-header>

    <!-- 主体内容 -->
    <el-container class="main-container">
      <!-- 侧边栏 -->
      <el-aside width="240px" class="aside">
        <el-menu
          :default-active="activeMenu"
          class="side-menu"
          router
          :collapse="false"
        >
          <div class="menu-group-title">系统管理</div>
          
          <el-menu-item index="/admin/dashboard">
            <el-icon><Odometer /></el-icon>
            <span>系统概览</span>
          </el-menu-item>
          
          <el-menu-item index="/admin/users">
            <el-icon><User /></el-icon>
            <span>用户管理</span>
          </el-menu-item>
          
          <el-menu-item index="/admin/courses">
            <el-icon><Reading /></el-icon>
            <span>课程管理</span>
          </el-menu-item>

          <el-menu-item index="/admin/instances">
            <el-icon><Calendar /></el-icon>
            <span>开课管理</span>
          </el-menu-item>

          <el-menu-item index="/admin/statistics">
            <el-icon><DataLine /></el-icon>
            <span>数据统计</span>
          </el-menu-item>

          <div class="menu-group-title mt-4">个人中心</div>

          <el-menu-item index="/admin/change-password">
            <el-icon><Lock /></el-icon>
            <span>修改密码</span>
          </el-menu-item>
        </el-menu>
      </el-aside>

      <!-- 内容区域 -->
      <el-main class="main-content">
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </el-main>
    </el-container>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { 
  School, Bell, ArrowDown, SwitchButton,
  Odometer, Reading, Calendar, User, Lock, DataLine
} from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const activeMenu = computed(() => route.path)

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}
</script>

<style scoped>
.layout-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: #f5f7fa;
}

.header {
  height: 64px;
  background-color: #fff;
  border-bottom: 1px solid #e4e7ed;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);
  z-index: 10;
}

.header-left {
  display: flex;
  align-items: center;
}

.logo-area {
  display: flex;
  align-items: center;
  gap: 12px;
}

.system-title {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
  letter-spacing: 0.5px;
}

.role-tag {
  margin-left: 8px;
  font-weight: normal;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 24px;
}

.action-items {
  display: flex;
  align-items: center;
  gap: 16px;
}

.action-item {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  cursor: pointer;
  color: #606266;
  transition: all 0.3s;
}

.action-item:hover {
  background-color: #fdf6ec;
  color: var(--warning-color);
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 8px;
  transition: all 0.3s;
}

.user-info:hover {
  background-color: #fdf6ec;
}

.user-avatar {
  background-color: var(--warning-color);
  color: #fff;
  font-weight: 600;
}

.user-details {
  display: flex;
  flex-direction: column;
  line-height: 1.2;
}

.username {
  font-size: 14px;
  font-weight: 500;
  color: #303133;
}

.user-id {
  font-size: 12px;
  color: #909399;
}

.dropdown-icon {
  font-size: 12px;
  color: #909399;
}

.main-container {
  flex: 1;
  overflow: hidden;
}

.aside {
  background-color: #fff;
  border-right: 1px solid #e4e7ed;
  display: flex;
  flex-direction: column;
}

.side-menu {
  border-right: none;
  padding: 16px 0;
}

.menu-group-title {
  padding: 8px 24px;
  font-size: 12px;
  color: #909399;
  margin-bottom: 4px;
}

.mt-4 {
  margin-top: 16px;
}

:deep(.el-menu-item) {
  height: 50px;
  margin: 4px 12px;
  border-radius: 8px;
  color: #606266;
}

:deep(.el-menu-item.is-active) {
  background-color: #fdf6ec;
  color: var(--warning-color);
  font-weight: 500;
}

:deep(.el-menu-item:hover) {
  background-color: #fdf6ec;
}

:deep(.el-menu-item .el-icon) {
  font-size: 18px;
  margin-right: 12px;
}

.main-content {
  padding: 24px;
  overflow-y: auto;
  background-color: #f5f7fa;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.dropdown-header {
  padding: 8px 16px;
  font-size: 12px;
  color: #909399;
  border-bottom: 1px solid #ebeef5;
  margin-bottom: 4px;
}
</style>
