<template>
  <div class="login-wrapper">
    <div class="login-container">
      <!-- Left Side: Brand & Visual -->
      <div class="login-visual">
        <div class="brand-content">
          <div class="logo-circle">
            <el-icon :size="40"><School /></el-icon>
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
            <div class="register-link">
              <el-button link type="primary" @click="showRegisterDialog = true">注册新账号</el-button>
            </div>
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

    <!-- 注册弹窗 -->
    <el-dialog
      v-model="showRegisterDialog"
      title="注册新账号"
      width="500px"
      :close-on-click-modal="false"
      @close="resetRegisterForm"
      append-to-body
    >
      <el-form
        ref="registerFormRef"
        :model="registerForm"
        :rules="registerRules"
        label-width="80px"
        status-icon
      >
        <el-form-item label="用户名" prop="username">
          <el-input v-model="registerForm.username" placeholder="请输入学号/工号" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input
            v-model="registerForm.password"
            type="password"
            placeholder="请输入密码"
            show-password
          />
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input
            v-model="registerForm.confirmPassword"
            type="password"
            placeholder="请再次输入密码"
            show-password
          />
        </el-form-item>
        <el-form-item label="姓名" prop="name">
          <el-input v-model="registerForm.name" placeholder="请输入真实姓名" />
        </el-form-item>
        <el-form-item label="角色" prop="role">
          <el-select v-model="registerForm.role" placeholder="请选择角色" style="width: 100%">
            <el-option label="学生" value="学生" />
            <el-option label="教师" value="教师" />
          </el-select>
        </el-form-item>
        <el-form-item label="院系" prop="department_id">
          <el-select v-model="registerForm.department_id" placeholder="请选择院系" style="width: 100%">
            <el-option
              v-for="dept in departments"
              :key="dept.department_id"
              :label="dept.department_name"
              :value="dept.department_id"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showRegisterDialog = false">取消</el-button>
          <el-button type="primary" :loading="registerLoading" @click="handleRegister">
            注册
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { register, getDepartments } from '@/api'
import { School, User, Lock, Avatar, Management, Check } from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()

const formRef = ref()
const loading = ref(false)

// 注册相关
const showRegisterDialog = ref(false)
const registerLoading = ref(false)
const registerFormRef = ref()
const departments = ref([])

const registerForm = reactive({
  username: '',
  password: '',
  confirmPassword: '',
  name: '',
  role: '学生',
  department_id: ''
})

const validatePass2 = (rule, value, callback) => {
  if (value === '') {
    callback(new Error('请再次输入密码'))
  } else if (value !== registerForm.password) {
    callback(new Error('两次输入密码不一致!'))
  } else {
    callback()
  }
}

const registerRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 1, max: 20, message: '长度在 1 到 20 个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 50, message: '长度在 6 到 50 个字符', trigger: 'blur' }
  ],
  confirmPassword: [{ validator: validatePass2, trigger: 'blur' }],
  name: [
    { required: true, message: '请输入姓名', trigger: 'blur' },
    { min: 1, max: 50, message: '长度在 1 到 50 个字符', trigger: 'blur' }
  ],
  role: [{ required: true, message: '请选择角色', trigger: 'change' }],
  department_id: [{ required: true, message: '请选择院系', trigger: 'change' }]
}

const fetchDepartments = async () => {
  try {
    const res = await getDepartments()
    departments.value = Array.isArray(res) ? res : []
  } catch (error) {
    console.error('获取院系失败', error)
    ElMessage.error('获取院系列表失败，请重试')
  }
}

const handleRegister = async () => {
  if (!registerFormRef.value) return
  await registerFormRef.value.validate(async (valid) => {
    if (valid) {
      registerLoading.value = true
      try {
        const { confirmPassword, ...data } = registerForm
        // 确保 department_id 是数字
        if (data.department_id) {
          data.department_id = Number(data.department_id)
        }
        console.log('Register data:', data)
        await register(data)
        ElMessage.success('注册成功，请登录')
        showRegisterDialog.value = false
      } catch (error) {
        if (!error.isHandled) {
          ElMessage.error(error.message || '注册失败')
        }
      } finally {
        registerLoading.value = false
      }
    }
  })
}

const resetRegisterForm = () => {
  if (registerFormRef.value) {
    registerFormRef.value.resetFields()
  }
}

// 监听弹窗打开获取院系
import { watch } from 'vue'
watch(showRegisterDialog, (val) => {
  if (val && departments.value.length === 0) {
    fetchDepartments()
  }
})

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
    { min: 6, max: 50, message: '长度在 6 到 50 个字符', trigger: 'blur' }
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
        if (!error.isHandled) {
          ElMessage.error(error.message || '登录失败')
        }
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
/* Clean / Modern University Theme */
.login-wrapper {
  height: 100vh;
  width: 100vw;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f0f2f5;
  background-image: url('../assets/images/bg-pattern.png'); /* Optional: subtle pattern if available, otherwise just color */
  position: relative;
  overflow: hidden;
}

.login-container {
  width: 1000px;
  height: 600px;
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.05);
  display: flex;
  overflow: hidden;
  position: relative;
}

/* Left Side */
.login-visual {
  flex: 1;
  background: linear-gradient(135deg, rgba(24, 144, 255, 0.9) 0%, rgba(54, 207, 201, 0.9) 100%), url('../assets/images/VCG211144730484.webp') center/cover no-repeat;
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 60px;
  color: #fff;
}

.brand-content {
  position: relative;
  z-index: 2;
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

.logo-circle :deep(.el-icon) {
  color: #fff;
}

.login-visual h1 {
  font-size: 32px;
  font-weight: 700;
  margin: 0 0 10px;
  line-height: 1.4;
  color: #fff;
}

.subtitle {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.85);
  margin: 0 0 40px;
  font-weight: 400;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.feature-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 15px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.9);
}

/* Right Side */
.login-form-section {
  flex: 1;
  padding: 60px 80px;
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
  font-weight: 600;
}

.form-header p {
  color: #909399;
  margin: 0;
  font-size: 14px;
}

.login-form {
  margin-bottom: 30px;
}

/* Input Styling - Revert to standard clean look */
:deep(.el-input__wrapper) {
  background-color: #fff !important;
  box-shadow: 0 0 0 1px #dcdfe6 inset !important;
  border-radius: 4px !important;
  padding: 8px 15px !important;
  transition: all 0.3s;
}

:deep(.el-input__wrapper:hover) {
  box-shadow: 0 0 0 1px #c0c4cc inset !important;
}

:deep(.el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 1px #409eff inset !important;
}

:deep(.el-input__inner) {
  color: #606266 !important;
  height: 40px;
}

.submit-btn {
  width: 100%;
  height: 44px;
  font-size: 16px;
  font-weight: 500;
  border-radius: 4px;
  margin-top: 10px;
  background: #409eff;
  border: none;
  color: #fff;
  letter-spacing: 1px;
  transition: all 0.3s;
}

.submit-btn:hover {
  background: #66b1ff;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
}

.register-link {
  text-align: center;
  margin-top: 16px;
}

.register-link :deep(.el-button) {
  color: #409eff;
  font-weight: normal;
}

/* Test Accounts */
.test-accounts-wrapper {
  margin-top: auto;
}

.divider {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
  color: #909399;
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
  padding: 0 12px;
}

.accounts-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.account-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 12px;
  cursor: pointer;
  transition: all 0.3s;
  background: #f5f7fa;
  color: #606266;
  gap: 8px;
  border-radius: 6px;
  border: 1px solid transparent;
}

.account-btn:hover {
  background: #ecf5ff;
  color: #409eff;
  border-color: #c6e2ff;
}

.account-btn.student:hover { color: #409eff; background: #ecf5ff; border-color: #c6e2ff; }
.account-btn.teacher:hover { color: #67c23a; background: #f0f9eb; border-color: #d1edc4; }
.account-btn.admin:hover { color: #e6a23c; background: #fdf6ec; border-color: #f5dab1; }

.account-btn span {
  font-size: 12px;
  font-weight: 500;
}
</style>
