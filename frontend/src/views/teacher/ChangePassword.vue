<template>
  <div class="change-password">
    <el-row justify="center">
      <el-col :xs="24" :sm="20" :md="16" :lg="12" :xl="10">
        <el-card class="main-card" shadow="hover">
          <template #header>
            <div class="card-header">
              <div class="header-left">
                <el-icon class="header-icon"><Lock /></el-icon>
                <span class="header-title">修改密码</span>
              </div>
              <div class="header-tip">
                为了您的账号安全，请定期更换密码
              </div>
            </div>
          </template>
          
          <div class="form-container">
            <el-form
              ref="formRef"
              :model="form"
              :rules="rules"
              label-position="top"
              size="large"
              class="password-form"
            >
              <el-form-item label="原密码" prop="oldPassword">
                <el-input
                  v-model="form.oldPassword"
                  type="password"
                  placeholder="请输入当前使用的密码"
                  show-password
                  :prefix-icon="Key"
                />
              </el-form-item>
              
              <el-form-item label="新密码" prop="newPassword">
                <el-input
                  v-model="form.newPassword"
                  type="password"
                  placeholder="请输入新密码（至少6位）"
                  show-password
                  :prefix-icon="Lock"
                />
                <div class="password-strength" v-if="form.newPassword">
                  <div class="strength-bar">
                    <div 
                      class="strength-fill" 
                      :class="strengthClass"
                      :style="{ width: strengthWidth }"
                    ></div>
                  </div>
                  <span class="strength-text">{{ strengthText }}</span>
                </div>
              </el-form-item>
              
              <el-form-item label="确认新密码" prop="confirmPassword">
                <el-input
                  v-model="form.confirmPassword"
                  type="password"
                  placeholder="请再次输入新密码"
                  show-password
                  :prefix-icon="Check"
                />
              </el-form-item>

              <el-form-item class="form-actions">
                <el-button @click="resetForm">重置</el-button>
                <el-button 
                  type="primary" 
                  @click="handleSubmit" 
                  :loading="loading"
                  class="submit-btn"
                >
                  确认修改
                </el-button>
              </el-form-item>
            </el-form>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { Lock, Key, Check } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const formRef = ref(null)
const loading = ref(false)

const form = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const validatePass = (rule, value, callback) => {
  if (value === '') {
    callback(new Error('请输入新密码'))
  } else {
    if (form.confirmPassword !== '') {
      if (formRef.value) formRef.value.validateField('confirmPassword')
    }
    callback()
  }
}

const validatePass2 = (rule, value, callback) => {
  if (value === '') {
    callback(new Error('请再次输入密码'))
  } else if (value !== form.newPassword) {
    callback(new Error('两次输入密码不一致!'))
  } else {
    callback()
  }
}

const rules = {
  oldPassword: [
    { required: true, message: '请输入原密码', trigger: 'blur' }
  ],
  newPassword: [
    { validator: validatePass, trigger: 'blur' },
    { min: 6, message: '密码长度不能小于6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { validator: validatePass2, trigger: 'blur' }
  ]
}

// 密码强度计算
const strengthScore = computed(() => {
  const pwd = form.newPassword
  let score = 0
  if (!pwd) return 0
  if (pwd.length >= 6) score += 1
  if (pwd.length >= 10) score += 1
  if (/[A-Z]/.test(pwd)) score += 1
  if (/[0-9]/.test(pwd)) score += 1
  if (/[^A-Za-z0-9]/.test(pwd)) score += 1
  return score
})

const strengthClass = computed(() => {
  if (strengthScore.value < 3) return 'weak'
  if (strengthScore.value < 5) return 'medium'
  return 'strong'
})

const strengthWidth = computed(() => {
  return `${Math.min(strengthScore.value * 20, 100)}%`
})

const strengthText = computed(() => {
  if (strengthScore.value < 3) return '弱'
  if (strengthScore.value < 5) return '中'
  return '强'
})

const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      try {
        await request.post('/auth/change-password', {
          old_password: form.oldPassword,
          new_password: form.newPassword
        }, {
          params: { user_id: authStore.userId }
        })
        ElMessage.success('密码修改成功，请重新登录')
        authStore.logout()
      } catch (error) {
        ElMessage.error(error.response?.data?.detail || '修改失败')
      } finally {
        loading.value = false
      }
    }
  })
}

const resetForm = () => {
  if (!formRef.value) return
  formRef.value.resetFields()
}
</script>

<style scoped>
.change-password {
  padding: 40px 20px;
}

.main-card {
  border-radius: 12px;
  border: none;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
}

.card-header {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.header-icon {
  font-size: 24px;
  color: var(--primary-color);
  background: var(--primary-color-light);
  padding: 8px;
  border-radius: 8px;
}

.header-title {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.header-tip {
  font-size: 13px;
  color: #909399;
  margin-left: 50px;
}

.form-container {
  padding: 20px 40px;
}

.password-form :deep(.el-form-item__label) {
  font-weight: 500;
}

.password-strength {
  margin-top: 8px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.strength-bar {
  flex: 1;
  height: 4px;
  background-color: #ebeef5;
  border-radius: 2px;
  overflow: hidden;
}

.strength-fill {
  height: 100%;
  transition: all 0.3s ease;
}

.strength-fill.weak { background-color: #f56c6c; }
.strength-fill.medium { background-color: #e6a23c; }
.strength-fill.strong { background-color: #67c23a; }

.strength-text {
  font-size: 12px;
  color: #909399;
  width: 20px;
}

.form-actions {
  margin-top: 40px;
  margin-bottom: 0;
}

.form-actions :deep(.el-form-item__content) {
  justify-content: flex-end;
  gap: 12px;
}

.submit-btn {
  min-width: 120px;
}

@media (max-width: 768px) {
  .form-container {
    padding: 10px 0;
  }
  
  .header-tip {
    margin-left: 0;
  }
}
</style>
