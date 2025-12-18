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
                为了您的账号安全，建议定期更换密码
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
              
              <el-form-item label="确认密码" prop="confirmPassword">
                <el-input
                  v-model="form.confirmPassword"
                  type="password"
                  placeholder="请再次输入新密码"
                  show-password
                  :prefix-icon="CircleCheck"
                />
              </el-form-item>
              
              <el-form-item class="form-actions">
                <el-button @click="resetForm">重置</el-button>
                <el-button type="primary" @click="handleSubmit" :loading="loading">
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
import { ref, reactive, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Lock, Key, CircleCheck } from '@element-plus/icons-vue'
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
      if (formRef.value) {
        formRef.value.validateField('confirmPassword')
      }
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
    { required: true, validator: validatePass, trigger: 'blur' },
    { min: 6, message: '密码长度不能小于6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, validator: validatePass2, trigger: 'blur' }
  ]
}

// Password strength calculation
const strengthScore = computed(() => {
  const pwd = form.newPassword
  if (!pwd) return 0
  let score = 0
  if (pwd.length >= 6) score++
  if (pwd.length >= 10) score++
  if (/[A-Z]/.test(pwd)) score++
  if (/[a-z]/.test(pwd)) score++
  if (/[0-9]/.test(pwd)) score++
  if (/[^A-Za-z0-9]/.test(pwd)) score++
  return score
})

const strengthClass = computed(() => {
  if (strengthScore.value < 3) return 'weak'
  if (strengthScore.value < 5) return 'medium'
  return 'strong'
})

const strengthWidth = computed(() => {
  if (strengthScore.value < 3) return '33%'
  if (strengthScore.value < 5) return '66%'
  return '100%'
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
        const res = await request.post('/auth/change-password', {
          old_password: form.oldPassword,
          new_password: form.newPassword
        }, {
          params: { user_id: authStore.userId }
        })
        
        if (res) {
          ElMessage.success('密码修改成功')
          resetForm()
        }
      } catch (error) {
        ElMessage.error(error.response?.data?.message || '修改失败')
      } finally {
        loading.value = false
      }
    }
  })
}

const resetForm = () => {
  if (formRef.value) {
    formRef.value.resetFields()
  }
}
</script>

<style scoped>
.change-password {
  min-height: 100%;
  padding: 20px;
}

.main-card {
  border: none;
  border-radius: 8px;
  box-shadow: var(--box-shadow-light);
}

:deep(.el-card__header) {
  padding: 20px 24px;
  border-bottom: 1px solid var(--border-color-light);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-icon {
  font-size: 20px;
  color: var(--primary-color);
  background: var(--primary-color-light);
  padding: 8px;
  border-radius: 8px;
}

.header-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-primary);
}

.header-tip {
  font-size: 13px;
  color: var(--text-secondary);
}

.form-container {
  padding: 20px 0;
}

.password-form {
  max-width: 100%;
}

.form-actions {
  margin-top: 32px;
  margin-bottom: 0;
}

:deep(.el-form-item__content) {
  justify-content: flex-end;
}

.password-strength {
  margin-top: 8px;
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
}

.strength-bar {
  flex: 1;
  height: 4px;
  background: #f0f2f5;
  border-radius: 2px;
  overflow: hidden;
}

.strength-fill {
  height: 100%;
  transition: all 0.3s ease;
  border-radius: 2px;
}

.strength-fill.weak { background: #F56C6C; }
.strength-fill.medium { background: #E6A23C; }
.strength-fill.strong { background: #67C23A; }

.strength-text {
  font-size: 12px;
  color: var(--text-secondary);
  min-width: 20px;
}
</style>
