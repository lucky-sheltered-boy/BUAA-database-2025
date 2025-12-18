<template>
  <div class="user-management">
    <div class="page-header">
      <div class="header-left">
        <h2>
          <el-icon><User /></el-icon>
          用户管理
          <span class="text-muted">管理系统所有用户账号信息</span>
        </h2>
      </div>
      <el-button type="primary" @click="showAddDialog">
        <el-icon><Plus /></el-icon> 添加用户
      </el-button>
    </div>

    <!-- 筛选器 -->
    <el-card shadow="hover" class="search-card">
      <el-form :inline="true" class="filter-form">
        <el-form-item label="角色">
          <el-select v-model="filters.role" placeholder="全部角色" clearable @change="fetchUsers" style="width: 150px">
            <el-option label="学生" value="学生" />
            <el-option label="教师" value="教师" />
            <el-option label="教务" value="教务" />
          </el-select>
        </el-form-item>
        <el-form-item label="院系">
          <el-select v-model="filters.department_id" placeholder="全部院系" clearable @change="fetchUsers" style="width: 180px">
            <el-option 
              v-for="dept in departments" 
              :key="dept.department_id" 
              :label="dept.department_name" 
              :value="dept.department_id" 
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchUsers" :loading="loading">
            <el-icon><Search /></el-icon> 查询
          </el-button>
          <el-button @click="resetFilters" icon="Refresh">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 用户列表 -->
    <el-card shadow="hover" class="data-card">
      <el-table :data="users" v-loading="loading" border stripe style="width: 100%">
        <el-table-column prop="user_id" label="ID" width="80" align="center" />
        <el-table-column prop="student_id" label="学号/工号" width="150" align="center">
          <template #default="{ row }">
            <span class="mono-font">{{ row.student_id }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="姓名" width="120" align="center">
          <template #default="{ row }">
            <span class="user-name">{{ row.name }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="role" label="角色" width="100" align="center">
          <template #default="{ row }">
            <el-tag 
              :type="row.role === '学生' ? 'success' : row.role === '教师' ? 'primary' : 'warning'"
              effect="light"
            >
              {{ row.role }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="department_name" label="院系" min-width="180" />
        <el-table-column label="操作" width="200" fixed="right" align="center">
          <template #default="{ row }">
            <el-button type="primary" link size="small" icon="Edit" @click="handleEdit(row)">编辑</el-button>
            <el-button type="warning" link size="small" icon="Key" @click="handleResetPassword(row)">重置密码</el-button>
            <el-button type="danger" link size="small" icon="Delete" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 添加/编辑用户对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? '编辑用户' : '添加用户'"
      width="500px"
      destroy-on-close
      class="custom-dialog"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="80px">
        <el-form-item label="角色" prop="role">
          <el-select v-model="form.role" placeholder="选择角色" :disabled="isEdit" style="width: 100%">
            <el-option label="学生" value="学生" />
            <el-option label="教师" value="教师" />
            <el-option label="教务" value="教务" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="学号/工号" prop="student_id">
          <el-input v-model="form.student_id" placeholder="请输入学号或工号" />
        </el-form-item>
        
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name" placeholder="请输入姓名" />
        </el-form-item>
        
        <el-form-item label="院系" prop="department_id" v-if="form.role !== '教务'">
          <el-select v-model="form.department_id" placeholder="选择院系" style="width: 100%">
            <el-option 
              v-for="dept in departments" 
              :key="dept.department_id" 
              :label="dept.department_name" 
              :value="dept.department_id" 
            />
          </el-select>
        </el-form-item>

        <el-form-item label="初始密码" prop="password" v-if="!isEdit">
          <el-input v-model="form.password" type="password" show-password placeholder="默认密码为123456" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit" :loading="submitting">
            确定
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete, Refresh, Search, User, Key } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref(null)

const users = ref([])
const departments = ref([])

const filters = reactive({
  role: '',
  department_id: ''
})

const form = reactive({
  user_id: null,
  role: '学生',
  student_id: '',
  name: '',
  department_id: '',
  password: ''
})

const rules = {
  role: [{ required: true, message: '请选择角色', trigger: 'change' }],
  student_id: [{ required: true, message: '请输入学号/工号', trigger: 'blur' }],
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  department_id: [{ required: true, message: '请选择院系', trigger: 'change' }]
}

const fetchDepartments = async () => {
  try {
    const res = await request.get('/admin/departments')
    departments.value = res
  } catch (error) {
    console.error('获取院系失败:', error)
  }
}

const fetchUsers = async () => {
  loading.value = true
  try {
    const res = await request.get('/admin/users', { params: filters })
    users.value = res
  } catch (error) {
    console.error('获取用户失败:', error)
    ElMessage.error('获取用户列表失败')
  } finally {
    loading.value = false
  }
}

const resetFilters = () => {
  filters.role = ''
  filters.department_id = ''
  fetchUsers()
}

const showAddDialog = () => {
  isEdit.value = false
  form.user_id = null
  form.role = '学生'
  form.student_id = ''
  form.name = ''
  form.department_id = ''
  form.password = '123456'
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(form, row)
  dialogVisible.value = true
}

const handleDelete = (row) => {
  ElMessageBox.confirm(
    `确定要删除用户 ${row.name} 吗？此操作不可恢复。`,
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await request.delete(`/admin/users/${row.user_id}`)
      ElMessage.success('删除成功')
      fetchUsers()
    } catch (error) {
      ElMessage.error('删除失败')
    }
  })
}

const handleResetPassword = (row) => {
  ElMessageBox.confirm(
    `确定要重置用户 ${row.name} 的密码吗？`,
    '提示',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await request.post(`/admin/users/${row.user_id}/reset-password`)
      ElMessage.success('密码重置成功')
    } catch (error) {
      ElMessage.error('密码重置失败')
    }
  })
}

const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      submitting.value = true
      try {
        if (isEdit.value) {
          await request.put(`/api/admin/users/${form.user_id}`, form)
          ElMessage.success('更新成功')
        } else {
          await request.post('/api/admin/users', form)
          ElMessage.success('创建成功')
        }
        dialogVisible.value = false
        fetchUsers()
      } catch (error) {
        console.error('提交失败:', error)
        ElMessage.error(error.response?.data?.detail || '提交失败')
      } finally {
        submitting.value = false
      }
    }
  })
}

onMounted(() => {
  fetchDepartments()
  fetchUsers()
})
</script>

<style scoped>
.user-management {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.header-left h2 {
  margin: 0;
  font-size: 24px;
  color: #303133;
  display: flex;
  align-items: center;
  gap: 10px;
}

.text-muted {
  font-size: 14px;
  color: #909399;
  margin-left: 10px;
  font-weight: normal;
}

.search-card {
  margin-bottom: 20px;
  border: none;
}

.data-card {
  border: none;
}

.mono-font {
  font-family: monospace;
  color: #606266;
}

.user-name {
  font-weight: bold;
  color: #303133;
}

.custom-dialog :deep(.el-dialog__body) {
  padding-top: 20px;
  padding-bottom: 20px;
}
</style>
