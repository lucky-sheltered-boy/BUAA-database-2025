<template>
  <div class="instance-management">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>开课管理</span>
          <el-button type="primary" @click="showAddDialog">
            <el-icon><Plus /></el-icon>
            创建开课实例
          </el-button>
        </div>
      </template>

      <!-- 筛选器 -->
      <el-form :inline="true" class="filter-form">
        <el-form-item label="学期">
          <el-select v-model="filters.semester_id" placeholder="全部学期" clearable @change="fetchInstances">
            <el-option 
              v-for="semester in semesters" 
              :key="semester.semester_id"
              :label="semester.semester_name"
              :value="semester.semester_id"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button @click="fetchInstances" :loading="loading">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </el-form-item>
      </el-form>

      <!-- 开课实例列表 -->
      <el-table :data="instances" v-loading="loading" border stripe>
        <el-table-column prop="instance_id" label="实例ID" width="80" />
        <el-table-column prop="course_name" label="课程名称" width="150" />
        <el-table-column prop="course_id" label="课程ID" width="100" />
        <el-table-column prop="semester_name" label="学期" width="150" />
        <el-table-column label="教室" width="120">
          <template #default="{ row }">
            {{ row.building }} {{ row.room_number }}
          </template>
        </el-table-column>
        <el-table-column label="名额" width="150">
          <template #default="{ row }">
            <el-tag type="success" size="small">内{{ row.quota_inner }}</el-tag>
            <el-tag type="warning" size="small" style="margin-left: 4px">外{{ row.quota_outer }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="已选" width="150">
          <template #default="{ row }">
            <el-tag type="success" size="small">{{ row.enrolled_inner }}</el-tag>
            <el-tag type="warning" size="small" style="margin-left: 4px">{{ row.enrolled_outer }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="teachers" label="教师" min-width="120" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="viewDetails(row)">
              <el-icon><View /></el-icon>
              详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 创建开课实例对话框 -->
    <el-dialog
      v-model="dialogVisible"
      title="创建开课实例"
      width="800px"
      :close-on-click-modal="false"
    >
      <el-steps :active="currentStep" finish-status="success" align-center>
        <el-step title="基本信息" />
        <el-step title="授课教师" />
        <el-step title="上课时间" />
      </el-steps>

      <!-- 步骤1: 基本信息 -->
      <div v-show="currentStep === 0" style="margin-top: 30px">
        <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
          <el-form-item label="课程" prop="course_id">
            <el-select v-model="form.course_id" placeholder="请选择课程" filterable>
              <el-option 
                v-for="course in courses" 
                :key="course.course_id"
                :label="`${course.course_name} (${course.course_id})`"
                :value="course.course_id"
              />
            </el-select>
          </el-form-item>

          <el-form-item label="学期" prop="semester_id">
            <el-select v-model="form.semester_id" placeholder="请选择学期">
              <el-option 
                v-for="semester in semesters" 
                :key="semester.semester_id"
                :label="semester.semester_name"
                :value="semester.semester_id"
              />
            </el-select>
          </el-form-item>

          <el-form-item label="教室" prop="classroom_id">
            <el-select v-model="form.classroom_id" placeholder="请选择教室" filterable>
              <el-option 
                v-for="classroom in classrooms" 
                :key="classroom.classroom_id"
                :label="`${classroom.building} ${classroom.room_number} (容量${classroom.capacity})`"
                :value="classroom.classroom_id"
              />
            </el-select>
          </el-form-item>

          <el-form-item label="对内名额" prop="quota_inner">
            <el-input-number v-model="form.quota_inner" :min="0" :max="200" />
            <span style="margin-left: 10px; color: #909399">本院系学生可选名额</span>
          </el-form-item>

          <el-form-item label="对外名额" prop="quota_outer">
            <el-input-number v-model="form.quota_outer" :min="0" :max="200" />
            <span style="margin-left: 10px; color: #909399">跨院系学生可选名额</span>
          </el-form-item>

          <el-alert 
            v-if="totalQuota > selectedClassroomCapacity && selectedClassroomCapacity > 0"
            title="警告：总名额超过教室容量！"
            type="warning"
            :closable="false"
            style="margin-bottom: 20px"
          >
            总名额 {{ totalQuota }} 人 > 教室容量 {{ selectedClassroomCapacity }} 人
          </el-alert>
        </el-form>
      </div>

      <!-- 步骤2: 授课教师 -->
      <div v-show="currentStep === 1" style="margin-top: 30px">
        <el-form :model="form" label-width="100px">
          <el-form-item label="授课教师">
            <el-select 
              v-model="form.teachers" 
              placeholder="请选择授课教师" 
              multiple 
              filterable
              style="width: 100%"
            >
              <el-option 
                v-for="teacher in teachers" 
                :key="teacher.user_id"
                :label="`${teacher.name} (${teacher.student_id}) - ${teacher.department_name}`"
                :value="teacher.user_id"
              />
            </el-select>
            <div style="margin-top: 8px; color: #909399; font-size: 13px">
              可选择多位教师共同授课
            </div>
          </el-form-item>
        </el-form>

        <el-alert
          title="提示"
          type="info"
          :closable="false"
        >
          选择的教师将在下一步配置具体的上课时间段时进行分配
        </el-alert>
      </div>

      <!-- 步骤3: 上课时间 -->
      <div v-show="currentStep === 2" style="margin-top: 30px">
        <el-button type="primary" size="small" @click="addTimeSlot" style="margin-bottom: 15px">
          <el-icon><Plus /></el-icon>
          添加时间段
        </el-button>

        <el-table :data="form.time_slots" border>
          <el-table-column label="星期" width="120">
            <template #default="{ row, $index }">
              <el-select v-model="row.weekday" placeholder="选择" size="small">
                <el-option label="星期一" value="星期一" />
                <el-option label="星期二" value="星期二" />
                <el-option label="星期三" value="星期三" />
                <el-option label="星期四" value="星期四" />
                <el-option label="星期五" value="星期五" />
                <el-option label="星期六" value="星期六" />
                <el-option label="星期日" value="星期日" />
              </el-select>
            </template>
          </el-table-column>

          <el-table-column label="时间" width="180">
            <template #default="{ row }">
              <el-select v-model="row.time_slot" placeholder="选择" size="small">
                <el-option label="08:00-09:50 (1-2节)" value="08:00-09:50" />
                <el-option label="10:10-12:00 (3-4节)" value="10:10-12:00" />
                <el-option label="14:00-15:50 (5-6节)" value="14:00-15:50" />
                <el-option label="16:10-18:00 (7-8节)" value="16:10-18:00" />
                <el-option label="19:00-20:50 (9-10节)" value="19:00-20:50" />
              </el-select>
            </template>
          </el-table-column>

          <el-table-column label="周次" width="200">
            <template #default="{ row }">
              <el-input-number v-model="row.start_week" :min="1" :max="20" size="small" style="width: 70px" />
              <span style="margin: 0 5px">-</span>
              <el-input-number v-model="row.end_week" :min="1" :max="20" size="small" style="width: 70px" />
            </template>
          </el-table-column>

          <el-table-column label="单双周" width="120">
            <template #default="{ row }">
              <el-select v-model="row.week_type" size="small">
                <el-option label="全部" value="全部" />
                <el-option label="单周" value="单周" />
                <el-option label="双周" value="双周" />
              </el-select>
            </template>
          </el-table-column>

          <el-table-column label="授课教师" min-width="150">
            <template #default="{ row }">
              <el-select v-model="row.teacher_id" placeholder="选择教师" size="small" clearable>
                <el-option 
                  v-for="tid in form.teachers" 
                  :key="tid"
                  :label="getTeacherName(tid)"
                  :value="tid"
                />
              </el-select>
            </template>
          </el-table-column>

          <el-table-column label="操作" width="80" fixed="right">
            <template #default="{ $index }">
              <el-button 
                link 
                type="danger" 
                size="small"
                @click="removeTimeSlot($index)"
              >
                删除
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <el-alert
          v-if="form.time_slots.length === 0"
          title="请至少添加一个上课时间段"
          type="warning"
          :closable="false"
          style="margin-top: 15px"
        />
      </div>

      <template #footer>
        <div style="display: flex; justify-content: space-between">
          <el-button v-if="currentStep > 0" @click="prevStep">
            上一步
          </el-button>
          <div style="flex: 1"></div>
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button 
            v-if="currentStep < 2" 
            type="primary" 
            @click="nextStep"
          >
            下一步
          </el-button>
          <el-button 
            v-else
            type="primary" 
            @click="handleSubmit" 
            :loading="submitting"
          >
            创建开课实例
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 查看详情对话框 -->
    <el-dialog
      v-model="detailVisible"
      title="开课实例详情"
      width="900px"
    >
      <el-descriptions :column="2" border v-if="selectedInstance">
        <el-descriptions-item label="课程名称">{{ selectedInstance.course_name }}</el-descriptions-item>
        <el-descriptions-item label="课程ID">{{ selectedInstance.course_id }}</el-descriptions-item>
        <el-descriptions-item label="学期">{{ selectedInstance.semester }}</el-descriptions-item>
        <el-descriptions-item label="教室">{{ selectedInstance.classroom }}</el-descriptions-item>
        <el-descriptions-item label="对内名额">{{ selectedInstance.quota_inner }}</el-descriptions-item>
        <el-descriptions-item label="对外名额">{{ selectedInstance.quota_outer }}</el-descriptions-item>
        <el-descriptions-item label="已选对内">{{ selectedInstance.enrolled_inner }}</el-descriptions-item>
        <el-descriptions-item label="已选对外">{{ selectedInstance.enrolled_outer }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, Refresh, View } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const detailVisible = ref(false)
const formRef = ref(null)
const currentStep = ref(0)

const instances = ref([])
const courses = ref([])
const semesters = ref([])
const classrooms = ref([])
const teachers = ref([])
const selectedInstance = ref(null)

const filters = reactive({
  semester_id: null
})

const form = reactive({
  course_id: null,
  semester_id: null,
  classroom_id: null,
  quota_inner: 30,
  quota_outer: 10,
  teachers: [],
  time_slots: []
})

const rules = {
  course_id: [{ required: true, message: '请选择课程', trigger: 'change' }],
  semester_id: [{ required: true, message: '请选择学期', trigger: 'change' }],
  classroom_id: [{ required: true, message: '请选择教室', trigger: 'change' }],
  quota_inner: [{ required: true, message: '请输入对内名额', trigger: 'blur' }],
  quota_outer: [{ required: true, message: '请输入对外名额', trigger: 'blur' }]
}

// 计算属性
const totalQuota = computed(() => form.quota_inner + form.quota_outer)

const selectedClassroomCapacity = computed(() => {
  const classroom = classrooms.value.find(c => c.classroom_id === form.classroom_id)
  return classroom ? classroom.capacity : 0
})

// 获取教师姓名
const getTeacherName = (teacherId) => {
  const teacher = teachers.value.find(t => t.user_id === teacherId)
  return teacher ? teacher.name : ''
}

// 添加时间段
const addTimeSlot = () => {
  form.time_slots.push({
    weekday: '',
    time_slot: '',
    start_week: 1,
    end_week: 16,
    week_type: '全部',
    teacher_id: null
  })
}

// 删除时间段
const removeTimeSlot = (index) => {
  form.time_slots.splice(index, 1)
}

// 步骤控制
const nextStep = async () => {
  if (currentStep.value === 0) {
    try {
      await formRef.value.validate()
      currentStep.value++
    } catch (error) {
      // 表单验证失败
    }
  } else {
    currentStep.value++
  }
}

const prevStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
  }
}

// 数据获取
const fetchInstances = async () => {
  loading.value = true
  try {
    const params = {}
    if (filters.semester_id) {
      params.semester_id = filters.semester_id
    }
    const res = await request.get('/admin/instances', { params })
    if (res.success) {
      instances.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取开课实例列表失败')
  } finally {
    loading.value = false
  }
}

const fetchCourses = async () => {
  try {
    const res = await request.get('/admin/courses')
    if (res.success) {
      courses.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取课程列表失败')
  }
}

const fetchSemesters = async () => {
  try {
    const res = await request.get('/admin/semesters')
    if (res.success) {
      semesters.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取学期列表失败')
  }
}

const fetchClassrooms = async () => {
  try {
    const res = await request.get('/admin/classrooms')
    if (res.success) {
      classrooms.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取教室列表失败')
  }
}

const fetchTeachers = async () => {
  try {
    const res = await request.get('/admin/users', { params: { role: '教师' } })
    if (res.success) {
      teachers.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取教师列表失败')
  }
}

const showAddDialog = () => {
  // 重置表单
  Object.assign(form, {
    course_id: null,
    semester_id: null,
    classroom_id: null,
    quota_inner: 30,
    quota_outer: 10,
    teachers: [],
    time_slots: []
  })
  currentStep.value = 0
  dialogVisible.value = true
}

const handleSubmit = async () => {
  // 验证教师
  if (form.teachers.length === 0) {
    ElMessage.warning('请至少选择一位授课教师')
    return
  }

  // 验证时间段
  if (form.time_slots.length === 0) {
    ElMessage.warning('请至少添加一个上课时间段')
    return
  }

  // 验证时间段是否完整
  for (const slot of form.time_slots) {
    if (!slot.weekday || !slot.time_slot) {
      ElMessage.warning('请填写完整的上课时间信息')
      return
    }
    if (!slot.teacher_id) {
      ElMessage.warning('请为每个时间段指定授课教师')
      return
    }
  }

  submitting.value = true
  try {
    // 转换时间段格式
    const timeSlots = form.time_slots.map(slot => ({
      weekday: slot.weekday,
      time_slot: slot.time_slot,
      start_week: slot.start_week,
      end_week: slot.end_week,
      week_type: slot.week_type,
      teacher_id: slot.teacher_id
    }))

    const data = {
      course_id: form.course_id,
      semester_id: form.semester_id,
      classroom_id: form.classroom_id,
      quota_inner: form.quota_inner,
      quota_outer: form.quota_outer,
      teachers: form.teachers,
      time_slots: timeSlots
    }

    const res = await request.post('/admin/instances', data)
    if (res.success) {
      ElMessage.success('创建开课实例成功')
      dialogVisible.value = false
      await fetchInstances()
    }
  } catch (error) {
    ElMessage.error(error.response?.data?.message || '创建开课实例失败')
  } finally {
    submitting.value = false
  }
}

const viewDetails = (row) => {
  selectedInstance.value = row
  detailVisible.value = true
}

onMounted(() => {
  fetchCourses()
  fetchSemesters()
  fetchClassrooms()
  fetchTeachers()
  fetchInstances()
})
</script>

<style scoped>
.instance-management {
  max-width: 1400px;
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

:deep(.el-steps) {
  margin-bottom: 20px;
}

:deep(.el-step__title) {
  font-size: 14px;
}
</style>
