<template>
  <div class="course-management">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>课程管理</span>
          <el-button type="primary" @click="showAddDialog">
            <el-icon><Plus /></el-icon>
            添加课程
          </el-button>
        </div>
      </template>

      <!-- 筛选器 -->
      <el-form :inline="true" class="filter-form">
        <el-form-item label="院系">
          <el-select v-model="filters.department_id" placeholder="全部院系" clearable @change="fetchCourses">
            <el-option 
              v-for="dept in departments" 
              :key="dept.department_id" 
              :label="dept.department_name" 
              :value="dept.department_id" 
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button @click="fetchCourses" :loading="loading">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </el-form-item>
      </el-form>

      <!-- 课程列表 -->
      <el-table :data="courses" v-loading="loading" border stripe>
        <el-table-column prop="course_id" label="课程ID" width="120" />
        <el-table-column prop="course_name" label="课程名称" />
        <el-table-column prop="credit" label="学分" width="100" />
        <el-table-column prop="department_name" label="开课院系" />
      </el-table>
    </el-card>

    <!-- 添加课程对话框 -->
    <el-dialog
      v-model="dialogVisible"
      title="添加课程"
      width="500px"
      :close-on-click-modal="false"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="课程ID" prop="course_id">
          <el-input v-model="form.course_id" placeholder="例如：CS101" />
        </el-form-item>
        <el-form-item label="课程名称" prop="course_name">
          <el-input v-model="form.course_name" placeholder="请输入课程名称" />
        </el-form-item>
        <el-form-item label="学分" prop="credit">
          <el-input-number v-model="form.credit" :min="0.5" :max="10" :step="0.5" />
        </el-form-item>
        <el-form-item label="开课院系" prop="department_id">
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

const courses = ref([])
const departments = ref([])

const filters = reactive({
  department_id: null
})

const form = reactive({
  course_id: '',
  course_name: '',
  credit: 3.0,
  department_id: null
})

const rules = {
  course_id: [
    { required: true, message: '请输入课程ID', trigger: 'blur' }
  ],
  course_name: [
    { required: true, message: '请输入课程名称', trigger: 'blur' }
  ],
  credit: [
    { required: true, message: '请输入学分', trigger: 'blur' }
  ],
  department_id: [
    { required: true, message: '请选择院系', trigger: 'change' }
  ]
}

const fetchCourses = async () => {
  loading.value = true
  try {
    const params = {}
    if (filters.department_id) params.department_id = filters.department_id

    const res = await request.get('/admin/courses', { params })
    if (res.success) {
      courses.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取课程列表失败')
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
    course_id: '',
    course_name: '',
    credit: 3.0,
    department_id: null
  })
  dialogVisible.value = true
}

const handleSubmit = async () => {
  try {
    await formRef.value.validate()
    
    submitting.value = true
    const res = await request.post('/admin/courses', form)
    
    if (res.success) {
      ElMessage.success(res.message || '添加课程成功')
      dialogVisible.value = false
      await fetchCourses()
    }
  } catch (error) {
    if (error.response?.data?.message) {
      ElMessage.error(error.response.data.message)
    } else if (typeof error === 'object' && !error.response) {
      // 表单验证失败
    } else {
      ElMessage.error('添加课程失败')
    }
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  fetchDepartments()
  fetchCourses()
})
</script>

<style scoped>
.course-management {
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
