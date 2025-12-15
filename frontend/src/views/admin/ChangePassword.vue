<template>
  <div class="change-password">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>修改密码</span>
        </div>
      </template>
      
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
        style="max-width: 500px"
      >
        <el-form-item label="原密码" prop="oldPassword">
          <el-input
            v-model="form.oldPassword"
            type="password"
            placeholder="请输入原密码"
            show-password
            clearable
          />
        </el-form-item>
        
        <el-form-item label="新密码" prop="newPassword">
          <el-input
            v-model="form.newPassword"
            type="password"
            placeholder="请输入新密码（至少6位）"
            show-password
            clearable
          />
        </el-form-item>
        
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input
            v-model="form.confirmPassword"
            type="password"
            placeholder="请再次输入新密码"
            show-password
            clearable
          />
        </el-form-item>
        
        <el-form-item>
          <el-button type="primary" @click="handleSubmit" :loading="loading">
            <el-icon><Check /></el-icon>
            确认修改
          </el-button>
          <el-button @click="handleReset">
            <el-icon><RefreshLeft /></el-icon>
            重置
          </el-button>
        </el-form-item>
      </el-form>
      
      <el-alert
        title="温馨提示"
        type="info"
        :closable="false"
        style="margin-top: 20px"
      >
        <ul style="margin: 0; padding-left: 20px">
          <li>新密码长度至少为6位</li>
          <li>建议使用字母、数字、符号组合，提高安全性</li>
          <li>修改密码后需要重新登录</li>
        </ul>
      </el-alert>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Check, RefreshLeft } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()

const formRef = ref(null)
const loading = ref(false)

const form = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

// 验证新密码
const validateNewPassword = (rule, value, callback) => {
  if (value === '') {
    callback(new Error('请输入新密码'))
  } else if (value.length < 6) {
    callback(new Error('新密码长度至少为6位'))
  } else if (value === form.oldPassword) {
    callback(new Error('新密码不能与原密码相同'))
  } else {
    if (form.confirmPassword !== '') {
      formRef.value.validateField('confirmPassword')
    }
    callback()
  }
}

// 验证确认密码
const validateConfirmPassword = (rule, value, callback) => {
  if (value === '') {
    callback(new Error('请再次输入新密码'))
  } else if (value !== form.newPassword) {
    callback(new Error('两次输入的密码不一致'))
  } else {
    callback()
  }
}

const rules = {
  oldPassword: [
    { required: true, message: '请输入原密码', trigger: 'blur' },
    { min: 6, message: '密码长度至少为6位', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, validator: validateNewPassword, trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, validator: validateConfirmPassword, trigger: 'blur' }
  ]
}

const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      try {
        const res = await request.post(
          `/auth/change-password?user_id=${authStore.userId}`,
          {
            old_password: form.oldPassword,
            new_password: form.newPassword
          }
        )
        
        if (res.success) {
          ElMessage.success(res.message || '密码修改成功')
          
          // 提示用户重新登录
          await ElMessageBox.confirm(
            '密码已修改成功，需要重新登录。是否立即跳转到登录页？',
            '修改成功',
            {
              confirmButtonText: '立即登录',
              cancelButtonText: '稍后',
              type: 'success'
            }
          ).then(() => {
            // 清除登录状态
            authStore.clearAuth()
            router.push('/login')
          }).catch(() => {
            // 用户点击"稍后"，也清除表单
            handleReset()
          })
        }
      } catch (error) {
        console.error('修改密码失败:', error)
        ElMessage.error(error.response?.data?.message || '修改密码失败')
      } finally {
        loading.value = false
      }
    }
  })
}

const handleReset = () => {
  formRef.value?.resetFields()
  form.oldPassword = ''
  form.newPassword = ''
  form.confirmPassword = ''
}
</script>

<style scoped>
.change-password {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: bold;
}

:deep(.el-form-item__label) {
  font-weight: 500;
}

:deep(.el-alert ul) {
  line-height: 1.8;
}
</style>
