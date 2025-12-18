<template>
  <div class="course-management">
    <el-card class="main-card" shadow="never">
      <template #header>
        <div class="card-header">
          <div class="header-left">
            <span class="header-title">课程管理</span>
            <el-tag type="info" effect="plain" class="count-tag">
              共 {{ courses.length }} 门课程
            </el-tag>
          </div>
          <div class="header-actions">
            <el-button type="primary" @click="showAddDialog">
              <el-icon><Plus /></el-icon>
              添加课程
            </el-button>
          </div>
        </div>
      </template>

      <div class="table-container">
        <!-- 筛选器 -->
        <div class="filter-bar">
          <el-form :inline="true" class="filter-form">
            <el-form-item label="院系筛选">
              <el-select 
                v-model="filters.department_id" 
                placeholder="全部院系" 
                clearable 
                @change="fetchCourses"
                style="width: 200px"
              >
                <el-option 
                  v-for="dept in departments" 
                  :key="dept.department_id" 
                  :label="dept.department_name" 
                  :value="dept.department_id" 
                />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button @click="fetchCourses" :loading="loading" plain>
                <el-icon><Refresh /></el-icon>
                刷新
              </el-button>
            </el-form-item>
          </el-form>
        </div>

        <!-- 课程列表 -->
        <el-table 
          :data="courses" 
          v-loading="loading" 
          stripe 
          style="width: 100%"
          :header-cell-style="{ background: '#f5f7fa', color: '#606266' }"
        >
          <el-table-column prop="course_id" label="课程ID" width="120" sortable>
            <template #default="{ row }">
              <span class="mono-font">{{ row.course_id }}</span>
            </template>
          </el-table-column>
          
          <el-table-column prop="course_name" label="课程名称" min-width="180">
            <template #default="{ row }">
              <span class="course-name">{{ row.course_name }}</span>
            </template>
          </el-table-column>
          
          <el-table-column prop="credit" label="学分" width="100" align="center">
            <template #default="{ row }">
              <el-tag type="success" effect="light" size="small">{{ row.credit }} 学分</el-tag>
            </template>
          </el-table-column>
          
          <el-table-column prop="department_name" label="开课院系" min-width="150">
            <template #default="{ row }">
              <el-tag type="info" effect="plain" size="small">{{ row.department_name }}</el-tag>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </el-card>

    <!-- 添加课程对话框 -->
    <el-dialog
      v-model="dialogVisible"
      title="添加课程"
      width="500px"
      :close-on-click-modal="false"
      destroy-on-close
      class="custom-dialog"
    >
      <el-form 
        :model="form" 
        :rules="rules" 
        ref="formRef" 
        label-width="100px"
        label-position="top"
      >
        <el-form-item label="课程ID" prop="course_id">
          <el-input v-model="form.course_id" placeholder="请输入课程ID" />
        </el-form-item>
        
        <el-form-item label="课程名称" prop="course_name">
          <el-input v-model="form.course_name" placeholder="请输入课程名称" />
        </el-form-item>
        
        <el-form-item label="学分" prop="credit">
          <el-input-number v-model="form.credit" :min="0.5" :step="0.5" :max="10" />
        </el-form-item>
        
        <el-form-item label="开课院系" prop="department_id">
          <el-select v-model="form.department_id" placeholder="请选择院系" style="width: 100%">
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
import { ElMessage } from 'element-plus'
import request from '@/utils/request'
import { Plus, Refresh } from '@element-plus/icons-vue'

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const formRef = ref(null)

const courses = ref([])
const departments = ref([])
const filters = reactive({
  department_id: ''
})

const form = reactive({
  course_id: '',
  course_name: '',
  credit: 2,
  department_id: ''
})

const rules = {
  course_id: [{ required: true, message: '请输入课程ID', trigger: 'blur' }],
  course_name: [{ required: true, message: '请输入课程名称', trigger: 'blur' }],
  credit: [{ required: true, message: '请输入学分', trigger: 'blur' }],
  department_id: [{ required: true, message: '请选择院系', trigger: 'change' }]
}

const fetchDepartments = async () => {
  try {
    const res = await request.get('/admin/departments')
    if (res) {
      departments.value = res
    }
  } catch (error) {
    console.error('Failed to fetch departments:', error)
  }
}

const fetchCourses = async () => {
  loading.value = true
  try {
    const res = await request.get('/admin/courses', {
      params: filters
    })
    if (res) {
      courses.value = res
    }
  } catch (error) {
    ElMessage.error('获取课程列表失败')
  } finally {
    loading.value = false
  }
}

const showAddDialog = () => {
  form.course_id = ''
  form.course_name = ''
  form.credit = 2
  form.department_id = ''
  dialogVisible.value = true
}

const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      submitting.value = true
      try {
        const res = await request.post('/admin/courses', form)
        if (res) {
          ElMessage.success('添加课程成功')
          dialogVisible.value = false
          fetchCourses()
        }
      } catch (error) {
        ElMessage.error(error.response?.data?.message || '添加失败')
      } finally {
        submitting.value = false
      }
    }
  })
}

onMounted(() => {
  fetchDepartments()
  fetchCourses()
})
</script>

<style scoped>
.course-management {
  min-height: 100%;
}

.main-card {
  border: none;
  background: transparent;
}

:deep(.el-card__header) {
  background: #fff;
  border-bottom: 1px solid var(--border-color-light);
  padding: 20px 24px;
  border-radius: 8px 8px 0 0;
}

:deep(.el-card__body) {
  padding: 0;
  background: #fff;
  border-radius: 0 0 8px 8px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.header-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-primary);
}

.table-container {
  padding: 20px;
}

.filter-bar {
  margin-bottom: 20px;
  padding-bottom: 20px;
  border-bottom: 1px solid var(--border-color-lighter);
}

.filter-form {
  margin-bottom: 0;
}

.mono-font {
  font-family: monospace;
  color: var(--text-regular);
}

.course-name {
  font-weight: 500;
  color: var(--text-primary);
}

/* Dialog Styles */
:deep(.custom-dialog) {
  border-radius: 8px;
  overflow: hidden;
}

:deep(.el-dialog__header) {
  margin: 0;
  padding: 20px 24px;
  border-bottom: 1px solid var(--border-color-light);
}

:deep(.el-dialog__body) {
  padding: 24px;
}

:deep(.el-dialog__footer) {
  padding: 16px 24px;
  border-top: 1px solid var(--border-color-light);
  background: #f8f9fa;
}
</style>
