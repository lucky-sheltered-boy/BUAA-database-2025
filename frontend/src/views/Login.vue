<template>
  <div class="login-container">
    <div class="login-box">
      <div class="login-header">
        <el-icon :size="50" color="#409EFF"><School /></el-icon>
        <h1>高校智能排课选课管理系统</h1>
        <p>Course Selection Management System</p>
      </div>

      <el-form
        ref="formRef"
        :model="loginForm"
        :rules="rules"
        class="login-form"
        @keyup.enter="handleLogin"
      >
        <el-form-item prop="username">
          <el-input
            v-model="loginForm.username"
            placeholder="请输入学号/工号"
            size="large"
            clearable
          >
            <template #prefix>
              <el-icon><User /></el-icon>
            </template>
          </el-input>
        </el-form-item>

        <el-form-item prop="password">
          <el-input
            v-model="loginForm.password"
            type="password"
            placeholder="请输入密码"
            size="large"
            show-password
          >
            <template #prefix>
              <el-icon><Lock /></el-icon>
            </template>
          </el-input>
        </el-form-item>

        <el-form-item>
          <el-button
            type="primary"
            size="large"
            :loading="loading"
            class="login-button"
            @click="handleLogin"
          >
            {{ loading ? '登录中...' : '登 录' }}
          </el-button>
        </el-form-item>
      </el-form>

      <div class="test-accounts">
        <el-divider>测试账号</el-divider>
        <div class="accounts-grid">
          <div class="account-card" @click="quickLogin('2021001', '123456')">
            <el-icon color="#409EFF"><User /></el-icon>
            <span>学生: 2021001</span>
          </div>
          <div class="account-card" @click="quickLogin('T001', '123456')">
            <el-icon color="#67C23A"><Avatar /></el-icon>
            <span>教师: T001</span>
          </div>
          <div class="account-card" @click="quickLogin('A001', '123456')">
            <el-icon color="#E6A23C"><Management /></el-icon>
            <span>教务: A001</span>
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
import { School, User, Lock, Avatar, Management } from '@element-plus/icons-vue'

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
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于6位', trigger: 'blur' }
  ]
}

const handleLogin = async () => {
  if (!formRef.value) return

  await formRef.value.validate(async (valid) => {
    if (!valid) return

    loading.value = true
    try {
      const userInfo = await authStore.login(loginForm.username, loginForm.password)
      
      ElMessage.success(`欢迎回来，${userInfo.name}！`)

      // 根据角色跳转
      const roleRoutes = {
        '学生': '/student/dashboard',
        '教师': '/teacher/dashboard',
        '教务': '/admin/dashboard'
      }
      
      router.push(roleRoutes[userInfo.role] || '/login')
    } catch (error) {
      ElMessage.error(error.response?.data?.detail || '登录失败')
    } finally {
      loading.value = false
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
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.login-box {
  width: 100%;
  max-width: 450px;
  background: white;
  border-radius: 16px;
  padding: 40px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.login-header {
  text-align: center;
  margin-bottom: 40px;
}

.login-header h1 {
  font-size: 24px;
  color: #303133;
  margin: 20px 0 10px;
}

.login-header p {
  font-size: 14px;
  color: #909399;
}

.login-form {
  margin-top: 30px;
}

.login-button {
  width: 100%;
  margin-top: 10px;
}

.test-accounts {
  margin-top: 30px;
}

.accounts-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
  margin-top: 15px;
}

.account-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 15px 10px;
  background: #f5f7fa;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
  font-size: 13px;
  color: #606266;
}

.account-card:hover {
  background: #ecf5ff;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.2);
}

:deep(.el-divider__text) {
  font-size: 13px;
  color: #909399;
}
</style>
