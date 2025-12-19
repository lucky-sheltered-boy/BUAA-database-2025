<template>
  <div class="instance-management">
    <div class="page-header">
      <div class="header-left">
        <h2>
          <el-icon><Calendar /></el-icon>
          开课实例管理
          <span class="text-muted">管理各学期的课程开设情况</span>
        </h2>
      </div>
      <el-button type="primary" @click="handleAdd">
        <el-icon><Plus /></el-icon> 新增开课
      </el-button>
    </div>

    <!-- 搜索栏 -->
    <el-card shadow="hover" class="search-card">
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="学期">
          <el-select v-model="searchForm.semester_id" placeholder="选择学期" clearable style="width: 180px">
            <el-option 
              v-for="semester in semesters" 
              :key="semester.semester_id" 
              :label="semester.semester_name" 
              :value="semester.semester_id" 
            />
          </el-select>
        </el-form-item>
        <el-form-item label="课程名称">
          <el-input v-model="searchForm.course_name" placeholder="输入课程名称搜索" clearable prefix-icon="Search" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="resetSearch" icon="Refresh">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 数据表格 -->
    <el-card shadow="hover" class="data-card">
      <el-table 
        v-loading="loading" 
        :data="instances" 
        style="width: 100%" 
        border 
        stripe
      >
        <el-table-column prop="instance_id" label="ID" width="80" align="center" />
        
        <el-table-column label="学期" width="150" align="center">
          <template #default="{ row }">
            <el-tag effect="plain">{{ row.semester_name }}</el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="course_name" label="课程名称" min-width="150">
          <template #default="{ row }">
            <span class="course-name">{{ row.course_name }}</span>
            <span class="course-id">({{ row.course_id }})</span>
          </template>
        </el-table-column>
        
        <el-table-column label="名额 (本/外)" width="140" align="center">
          <template #default="{ row }">
            <div class="quota-tags">
              <el-tag type="success" size="small" effect="light">本 {{ row.quota_inner }}</el-tag>
              <el-tag type="warning" size="small" effect="light">外 {{ row.quota_outer }}</el-tag>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column label="教师" min-width="150">
          <template #default="{ row }">
            <div class="teachers-cell">
              <el-tag 
                v-for="teacher in row.teachers" 
                :key="teacher.teacher_id"
                size="small"
                effect="plain"
                class="teacher-tag"
              >
                {{ teacher.name }}
              </el-tag>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="上课时间/地点" min-width="200">
          <template #default="{ row }">
            <div class="schedule-info">
              <div class="location">
                <el-icon><Location /></el-icon>
                {{ row.building }} {{ row.room_number }}
              </div>
              <div class="time-slots">
                <div v-for="(slot, idx) in row.time_slots" :key="idx" class="time-slot">
                  <el-icon><Timer /></el-icon>
                  {{ getDayName(slot.day_of_week) }} 第{{ slot.period }}节
                </div>
              </div>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="180" fixed="right" align="center">
          <template #default="{ row }">
            <el-button type="primary" link size="small" icon="Edit" @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link size="small" icon="Delete" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 创建/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? '编辑开课实例' : '创建开课实例'"
      width="800px"
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
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="课程" prop="course_id">
              <el-select 
                v-model="form.course_id" 
                placeholder="选择课程" 
                filterable 
                :disabled="isEdit"
                style="width: 100%"
              >
                <el-option 
                  v-for="course in courses" 
                  :key="course.course_id" 
                  :label="`${course.course_name} (${course.course_id})`" 
                  :value="course.course_id" 
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="学期" prop="semester_id">
              <el-select 
                v-model="form.semester_id" 
                placeholder="选择学期" 
                :disabled="isEdit"
                style="width: 100%"
              >
                <el-option 
                  v-for="semester in semesters" 
                  :key="semester.semester_id" 
                  :label="semester.semester_name" 
                  :value="semester.semester_id" 
                />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="本院名额" prop="quota_inner">
              <el-input-number v-model="form.quota_inner" :min="0" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="外院名额" prop="quota_outer">
              <el-input-number v-model="form.quota_outer" :min="0" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="教室" prop="classroom_id">
          <el-select 
            v-model="form.classroom_id" 
            placeholder="选择教室" 
            filterable
            style="width: 100%"
          >
            <el-option 
              v-for="room in classrooms" 
              :key="room.classroom_id" 
              :label="`${room.building} ${room.room_number} (容量: ${room.capacity})`" 
              :value="room.classroom_id" 
            />
          </el-select>
        </el-form-item>

        <el-form-item label="授课教师" prop="teacher_ids">
          <el-select 
            v-model="form.teacher_ids" 
            multiple 
            placeholder="选择教师" 
            filterable
            style="width: 100%"
          >
            <el-option 
              v-for="teacher in teachers" 
              :key="teacher.user_id" 
              :label="`${teacher.name} (${teacher.student_id})`" 
              :value="teacher.user_id" 
            />
          </el-select>
        </el-form-item>

        <el-form-item label="上课时间" required>
          <div v-for="(slot, index) in form.time_slots" :key="index" class="time-slot-item">
            <el-row :gutter="10">
              <el-col :span="10">
                <el-select v-model="slot.day_of_week" placeholder="星期" style="width: 100%">
                  <el-option label="星期一" :value="1" />
                  <el-option label="星期二" :value="2" />
                  <el-option label="星期三" :value="3" />
                  <el-option label="星期四" :value="4" />
                  <el-option label="星期五" :value="5" />
                  <el-option label="星期六" :value="6" />
                  <el-option label="星期日" :value="7" />
                </el-select>
              </el-col>
              <el-col :span="10">
                <el-select v-model="slot.period" placeholder="节次" style="width: 100%">
                  <el-option v-for="i in 14" :key="i" :label="`第 ${i} 节`" :value="i" />
                </el-select>
              </el-col>
              <el-col :span="4">
                <el-button 
                  type="danger" 
                  :icon="Delete" 
                  circle 
                  size="small" 
                  @click="removeTimeSlot(index)" 
                  v-if="form.time_slots.length > 1"
                />
              </el-col>
            </el-row>
          </div>
          <el-button type="primary" link :icon="Plus" @click="addTimeSlot" class="mt-2">
            添加时间段
          </el-button>
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
import { Plus, Edit, Delete, Search, Refresh, Calendar, Location, Timer } from '@element-plus/icons-vue'
import request from '@/utils/request'

// 状态定义
const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref(null)

const instances = ref([])
const courses = ref([])
const semesters = ref([])
const teachers = ref([])
const classrooms = ref([])

const searchForm = reactive({
  semester_id: '',
  course_name: ''
})

const form = reactive({
  instance_id: null,
  course_id: '',
  semester_id: '',
  classroom_id: '',
  quota_inner: 0,
  quota_outer: 0,
  teacher_ids: [],
  time_slots: [{ day_of_week: '', period: '' }]
})

const rules = {
  course_id: [{ required: true, message: '请选择课程', trigger: 'change' }],
  semester_id: [{ required: true, message: '请选择学期', trigger: 'change' }],
  classroom_id: [{ required: true, message: '请选择教室', trigger: 'change' }],
  quota_inner: [{ required: true, message: '请输入本院名额', trigger: 'blur' }],
  quota_outer: [{ required: true, message: '请输入外院名额', trigger: 'blur' }],
  teacher_ids: [{ required: true, message: '请选择授课教师', trigger: 'change' }]
}

// 获取数据
const fetchData = async () => {
  loading.value = true
  try {
    // 过滤掉空值参数
    const params = {}
    if (searchForm.semester_id) params.semester_id = searchForm.semester_id
    if (searchForm.course_name) params.course_name = searchForm.course_name

    const [instancesRes, coursesRes, semestersRes, teachersRes, classroomsRes] = await Promise.all([
      request.get('/admin/instances', { params }),
      request.get('/admin/courses'),
      request.get('/admin/semesters'),
      request.get('/admin/users', { params: { role: '教师' } }),
      request.get('/admin/classrooms')
    ])
    instances.value = instancesRes
    courses.value = coursesRes
    semesters.value = semestersRes
    teachers.value = teachersRes
    classrooms.value = classroomsRes
  } catch (error) {
    console.error('获取数据失败:', error)
    ElMessage.error('获取数据失败')
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  fetchData()
}

const resetSearch = () => {
  searchForm.semester_id = ''
  searchForm.course_name = ''
  fetchData()
}

// 表单操作
const handleAdd = () => {
  isEdit.value = false
  form.instance_id = null
  form.course_id = ''
  form.semester_id = ''
  form.classroom_id = ''
  form.quota_inner = 0
  form.quota_outer = 0
  form.teacher_ids = []
  form.time_slots = [{ day_of_week: '', period: '' }]
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(form, row)
  // 确保 teacher_ids 是数组
  form.teacher_ids = row.teachers.map(t => t.teacher_id)
  // 确保 time_slots 格式正确
  form.time_slots = row.time_slots.length > 0 ? [...row.time_slots] : [{ day_of_week: '', period: '' }]
  // 查找教室ID (这里可能需要后端返回classroom_id，目前只能尝试匹配)
  // 暂时无法回显教室，因为列表接口没返回classroom_id
  dialogVisible.value = true
}

const handleDelete = (row) => {
  ElMessageBox.confirm(
    `确定要删除该开课实例吗？此操作不可恢复。`,
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await request.delete(`/admin/instances/${row.instance_id}`)
      ElMessage.success('删除成功')
      fetchData()
    } catch (error) {
      ElMessage.error('删除失败')
    }
  })
}

const addTimeSlot = () => {
  form.time_slots.push({ day_of_week: '', period: '' })
}

const removeTimeSlot = (index) => {
  form.time_slots.splice(index, 1)
}

const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      // 验证时间段
      for (const slot of form.time_slots) {
        if (!slot.day_of_week || !slot.period) {
          ElMessage.warning('请完善上课时间信息')
          return
        }
      }

      submitting.value = true
      try {
        // 构造符合后端要求的数据格式
        const data = {
          course_id: form.course_id,
          semester_id: form.semester_id,
          classroom_id: form.classroom_id,
          quota_inner: form.quota_inner,
          quota_outer: form.quota_outer,
          teachers: form.teacher_ids,
          time_slots: form.time_slots.map(slot => ({
            weekday: slot.day_of_week,
            time_slot: slot.period,
            start_week: 1, // 默认值
            end_week: 16,  // 默认值
            week_type: '全部', // 默认值
            teacher_id: form.teacher_ids[0] // 默认使用第一个教师
          }))
        }
        
        if (isEdit.value) {
          await request.put(`/admin/instances/${form.instance_id}`, data)
          ElMessage.success('更新成功')
        } else {
          await request.post('/admin/instances', data)
          ElMessage.success('创建成功')
        }
        dialogVisible.value = false
        fetchData()
      } catch (error) {
        console.error('提交失败:', error)
        ElMessage.error(error.response?.data?.detail || '提交失败')
      } finally {
        submitting.value = false
      }
    }
  })
}

// 辅助函数
const getSemesterName = (id) => {
  const semester = semesters.value.find(s => s.semester_id === id)
  return semester ? semester.semester_name : id
}

const getDayName = (day) => {
  const days = ['一', '二', '三', '四', '五', '六', '日']
  return days[day - 1] || day
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.instance-management {
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

.course-name {
  font-weight: bold;
  color: #303133;
  display: block;
}

.course-id {
  font-size: 12px;
  color: #909399;
}

.quota-tags {
  display: flex;
  flex-direction: column;
  gap: 4px;
  align-items: center;
}

.teachers-cell {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.teacher-tag {
  margin-right: 0;
}

.schedule-info {
  font-size: 13px;
}

.location {
  color: #606266;
  margin-bottom: 4px;
  display: flex;
  align-items: center;
  gap: 4px;
}

.time-slots {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.time-slot {
  color: #409EFF;
  display: flex;
  align-items: center;
  gap: 4px;
}

.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}

.time-slot-item {
  margin-bottom: 10px;
  padding: 10px;
  background-color: #f5f7fa;
  border-radius: 4px;
}

.mt-2 {
  margin-top: 8px;
}

.custom-dialog :deep(.el-dialog__body) {
  padding-top: 20px;
  padding-bottom: 20px;
}
</style>
