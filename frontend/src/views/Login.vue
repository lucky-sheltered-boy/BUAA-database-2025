<template>
  <div class="login-wrapper">
    <div class="login-container">
      <!-- Left Side: Brand & Visual -->
      <div class="login-visual">
        <div class="brand-content">
          <div class="logo-circle">
            <el-icon :size="40" color="#fff"><School /></el-icon>
          </div>
          <h1>高校课程选课管理系统</h1>
          <p class="subtitle">Course Selection Management System</p>
          <div class="feature-list">
            <div class="feature-item">
              <el-icon><Check /></el-icon> 智能排课算法
            </div>
            <div class="feature-item">
              <el-icon><Check /></el-icon> 实时选课系统
            </div>
            <div class="feature-item">
              <el-icon><Check /></el-icon> 多角色权限管理
            </div>
          </div>
        </div>
        <div class="visual-bg"></div>
      </div>

      <!-- Right Side: Login Form -->
      <div class="login-form-section">
        <div class="form-header">
          <h2>欢迎登录</h2>
          <p>请输入您的账号和密码以继续</p>
        </div>

        <el-form
          ref="formRef"
          :model="loginForm"
          :rules="rules"
          class="login-form"
          @keyup.enter="handleLogin"
          size="large"
        >
          <el-form-item prop="username">
            <el-input
              v-model="loginForm.username"
              placeholder="学号 / 工号"
              :prefix-icon="User"
            />
          </el-form-item>

          <el-form-item prop="password">
            <el-input
              v-model="loginForm.password"
              type="password"
              placeholder="密码"
              show-password
              :prefix-icon="Lock"
            />
          </el-form-item>

          <el-form-item>
            <el-button
              type="primary"
              :loading="loading"
              class="submit-btn"
              @click="handleLogin"
            >
              {{ loading ? '登录中...' : '登 录' }}
            </el-button>
          </el-form-item>
        </el-form>

        <div class="test-accounts-wrapper">
          <div class="divider">
            <span>快速测试通道</span>
          </div>
          <div class="accounts-grid">
            <div class="account-btn student" @click="quickLogin('2021001', '123456')">
              <el-icon><User /></el-icon>
              <span>学生</span>
            </div>
            <div class="account-btn teacher" @click="quickLogin('T1001', '123456')">
              <el-icon><Avatar /></el-icon>
              <span>教师</span>
            </div>
            <div class="account-btn admin" @click="quickLogin('A001', '123456')">
              <el-icon><Management /></el-icon>
              <span>教务</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { School, User, Lock, Avatar, Management, Check } from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()

const formRef = ref()
const loading = ref(false)

const loginForm = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [
    { required: true, message: '请输入学号/工号', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' }
  ]
}

const handleLogin = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      try {
        const userInfo = await authStore.login(loginForm.username, loginForm.password)
        ElMessage.success('欢迎回来')
        
        // 根据角色跳转
        const roleRoutes = {
          '学生': '/student/dashboard',
          '教师': '/teacher/dashboard',
          '教务': '/admin/dashboard'
        }
        router.push(roleRoutes[userInfo.role] || '/')
      } catch (error) {
        ElMessage.error(error.response?.data?.message || '登录失败')
      } finally {
        loading.value = false
      }
    }
  })
}

const quickLogin = (username, password) => {
  loginForm.username = username
  loginForm.password = password
  handleLogin()
}
</script>

<style scoped>
.login-wrapper {
  height: 100vh;
  width: 100vw;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f0f2f5;
  background-image: radial-gradient(#e1e6ed 1px, transparent 1px);
  background-size: 20px 20px;
}

.login-container {
  width: 1000px;
  height: 600px;
  background: #fff;
  border-radius: 20px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.1);
  display: flex;
  overflow: hidden;
}

/* Left Side */
.login-visual {
  flex: 1;
  background: linear-gradient(135deg, #1890ff 0%, #36cfc9 100%);
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 60px;
  color: #fff;
}

.visual-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-image: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
}

.brand-content {
  position: relative;
  z-index: 1;
}

.logo-circle {
  width: 80px;
  height: 80px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 30px;
  backdrop-filter: blur(10px);
}

.login-visual h1 {
  font-size: 32px;
  font-weight: 600;
  margin: 0 0 10px;
  line-height: 1.4;
}

.subtitle {
  font-size: 16px;
  opacity: 0.8;
  margin: 0 0 40px;
  font-weight: 300;
}

.feature-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 16px;
  opacity: 0.9;
}

/* Right Side */
.login-form-section {
  flex: 1;
  padding: 60px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  background: #fff;
}

.form-header {
  margin-bottom: 40px;
}

.form-header h2 {
  font-size: 28px;
  color: #303133;
  margin: 0 0 10px;
}

.form-header p {
  color: #909399;
  margin: 0;
}

.login-form {
  margin-bottom: 30px;
}

.submit-btn {
  width: 100%;
  height: 44px;
  font-size: 16px;
  border-radius: 8px;
  margin-top: 10px;
}

/* Test Accounts */
.test-accounts-wrapper {
  margin-top: auto;
}

.divider {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
  color: #c0c4cc;
  font-size: 12px;
}

.divider::before,
.divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: #ebeef5;
}

.divider span {
  padding: 0 15px;
}

.accounts-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 15px;
}

.account-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 15px 10px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
  background: #f5f7fa;
  color: #606266;
  gap: 8px;
}

.account-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.account-btn.student:hover {
  background: #ecf5ff;
  color: #409eff;
}

.account-btn.teacher:hover {
  background: #f0f9eb;
  color: #67c23a;
}

.account-btn.admin:hover {
  background: #fdf6ec;
  color: #e6a23c;
}

.account-btn span {
  font-size: 12px;
}
</style>
