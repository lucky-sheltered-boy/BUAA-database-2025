<template>
  <div class="user-management">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>用户管理</span>
          <el-button type="primary" @click="showAddDialog">
            <el-icon><Plus /></el-icon>
            添加用户
          </el-button>
        </div>
      </template>

      <!-- 筛选器 -->
      <el-form :inline="true" class="filter-form">
        <el-form-item label="角色">
          <el-select v-model="filters.role" placeholder="全部角色" clearable @change="fetchUsers">
            <el-option label="学生" value="学生" />
            <el-option label="教师" value="教师" />
            <el-option label="教务" value="教务" />
          </el-select>
        </el-form-item>
        <el-form-item label="院系">
          <el-select v-model="filters.department_id" placeholder="全部院系" clearable @change="fetchUsers">
            <el-option 
              v-for="dept in departments" 
              :key="dept.department_id" 
              :label="dept.department_name" 
              :value="dept.department_id" 
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button @click="fetchUsers" :loading="loading">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </el-form-item>
      </el-form>

      <!-- 用户列表 -->
      <el-table :data="users" v-loading="loading" border stripe>
        <el-table-column prop="user_id" label="用户ID" width="80" />
        <el-table-column prop="student_id" label="学号/工号" width="120" />
        <el-table-column prop="name" label="姓名" width="120" />
        <el-table-column prop="role" label="角色" width="100">
          <template #default="{ row }">
            <el-tag 
              :type="row.role === '学生' ? 'success' : row.role === '教师' ? 'primary' : 'warning'"
            >
              {{ row.role }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="department_name" label="所属院系" />
      </el-table>
    </el-card>

    <!-- 添加用户对话框 -->
    <el-dialog
      v-model="dialogVisible"
      title="添加用户"
      width="500px"
      :close-on-click-modal="false"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="学号/工号" prop="student_id">
          <el-input v-model="form.student_id" placeholder="请输入学号或工号" />
        </el-form-item>
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name" placeholder="请输入姓名" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input v-model="form.password" type="password" placeholder="请输入密码（至少6位）" />
        </el-form-item>
        <el-form-item label="角色" prop="role">
          <el-select v-model="form.role" placeholder="请选择角色">
            <el-option label="学生" value="学生" />
            <el-option label="教师" value="教师" />
            <el-option label="教务" value="教务" />
          </el-select>
        </el-form-item>
        <el-form-item label="所属院系" prop="department_id">
          <el-select v-model="form.department_id" placeholder="请选择院系">
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
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, Refresh } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const formRef = ref(null)

const users = ref([])
const departments = ref([])

const filters = reactive({
  role: '',
  department_id: null
})

const form = reactive({
  student_id: '',
  name: '',
  password: '',
  role: '',
  department_id: null
})

const rules = {
  student_id: [
    { required: true, message: '请输入学号/工号', trigger: 'blur' }
  ],
  name: [
    { required: true, message: '请输入姓名', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码至少6位', trigger: 'blur' }
  ],
  role: [
    { required: true, message: '请选择角色', trigger: 'change' }
  ],
  department_id: [
    { required: true, message: '请选择院系', trigger: 'change' }
  ]
}

const fetchUsers = async () => {
  loading.value = true
  try {
    const params = {}
    if (filters.role) params.role = filters.role
    if (filters.department_id) params.department_id = filters.department_id

    const res = await request.get('/admin/users', { params })
    if (res.success) {
      users.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取用户列表失败')
  } finally {
    loading.value = false
  }
}

const fetchDepartments = async () => {
  try {
    const res = await request.get('/admin/departments')
    if (res.success) {
      departments.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取院系列表失败')
  }
}

const showAddDialog = () => {
  // 重置表单
  Object.assign(form, {
    student_id: '',
    name: '',
    password: '',
    role: '',
    department_id: null
  })
  dialogVisible.value = true
}

const handleSubmit = async () => {
  try {
    await formRef.value.validate()
    
    submitting.value = true
    const res = await request.post('/admin/users', form)
    
    if (res.success) {
      ElMessage.success(res.message || '添加用户成功')
      dialogVisible.value = false
      await fetchUsers()
    }
  } catch (error) {
    if (error.response?.data?.message) {
      ElMessage.error(error.response.data.message)
    } else if (typeof error === 'object' && !error.response) {
      // 表单验证失败
    } else {
      ElMessage.error('添加用户失败')
    }
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  fetchDepartments()
  fetchUsers()
})
</script>

<style scoped>
.user-management {
  max-width: 1200px;
  margin: 0 auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.filter-form {
  margin-bottom: 20px;
}
</style>
