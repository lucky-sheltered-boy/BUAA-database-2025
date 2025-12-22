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
          <div class="time-selection-container">
             <div class="time-grid-header">
               <div class="grid-cell-header"></div>
               <div v-for="day in weekDays" :key="day" class="grid-cell-header">{{ day }}</div>
             </div>
             <div class="time-grid-body">
               <div v-for="period in periods" :key="period.id" class="grid-row">
                 <div class="grid-cell-label">{{ period.label }}</div>
                 <div v-for="(day, dayIdx) in weekDays" :key="dayIdx" 
                      class="grid-cell"
                      :class="{
                        'is-selected': isSelected(dayIdx + 1, period.id),
                        'is-occupied': isOccupied(dayIdx + 1, period.id),
                        'is-disabled': !form.classroom_id || !form.semester_id
                      }"
                      @click="toggleTimeSlot(dayIdx + 1, period.id)"
                 >
                   <span v-if="isOccupied(dayIdx + 1, period.id)" class="occupied-text">已占</span>
                   <el-icon v-if="isSelected(dayIdx + 1, period.id)"><Check /></el-icon>
                 </div>
               </div>
             </div>
          </div>
          <div class="time-legend">
             <span class="legend-item"><span class="color-box occupied"></span> 已占用</span>
             <span class="legend-item"><span class="color-box selected"></span> 已选择</span>
             <span class="legend-item"><span class="color-box available"></span> 可选</span>
          </div>
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
import { ref, reactive, onMounted, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete, Search, Refresh, Calendar, Location, Timer, Check } from '@element-plus/icons-vue'
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
const classroomOccupiedSlots = ref([])
const teacherOccupiedSlots = ref([])

const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
const periods = [
  { id: 1, label: '第1-2节', startTime: '08:00:00' },
  { id: 2, label: '第3-4节', startTime: '10:00:00' },
  { id: 3, label: '第5-6节', startTime: '14:00:00' },
  { id: 4, label: '第7-8节', startTime: '16:00:00' },
  { id: 5, label: '第9-10节', startTime: '19:00:00' }
]

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
  time_slots: []
})

const rules = {
  course_id: [{ required: true, message: '请选择课程', trigger: 'change' }],
  semester_id: [{ required: true, message: '请选择学期', trigger: 'change' }],
  classroom_id: [{ required: true, message: '请选择教室', trigger: 'change' }],
  quota_inner: [{ required: true, message: '请输入本院名额', trigger: 'blur' }],
  quota_outer: [{ required: true, message: '请输入外院名额', trigger: 'blur' }],
  teacher_ids: [{ required: true, message: '请选择授课教师', trigger: 'change' }]
}

// 时间段选择相关逻辑
const fetchClassroomOccupiedSlots = async () => {
  if (!form.classroom_id || !form.semester_id) {
    classroomOccupiedSlots.value = []
    return
  }
  
  try {
    const res = await request.get(`/admin/classrooms/${form.classroom_id}/occupied-slots`, {
      params: { semester_id: form.semester_id }
    })
    classroomOccupiedSlots.value = res || []
  } catch (error) {
    console.error('获取教室占用时间段失败', error)
    classroomOccupiedSlots.value = []
  }
}

const fetchTeacherOccupiedSlots = async () => {
  if (!form.teacher_ids || form.teacher_ids.length === 0 || !form.semester_id) {
    teacherOccupiedSlots.value = []
    return
  }
  
  try {
    const promises = form.teacher_ids.map(tid => 
      request.get(`/admin/teachers/${tid}/occupied-slots`, {
        params: { semester_id: form.semester_id }
      })
    )
    const results = await Promise.all(promises)
    teacherOccupiedSlots.value = results.flat()
  } catch (error) {
    console.error('获取教师占用时间段失败', error)
    teacherOccupiedSlots.value = []
  }
}

watch(() => [form.classroom_id, form.semester_id], () => {
  fetchClassroomOccupiedSlots()
})

watch(() => [form.teacher_ids, form.semester_id], () => {
  fetchTeacherOccupiedSlots()
}, { deep: true })

const isOccupied = (dayIdx, periodId) => {
  const period = periods.find(p => p.id === periodId)
  if (!period) return false
  
  const dbWeekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日']
  const targetDayStr = dbWeekDays[dayIdx - 1]
  
  const checkSlot = (slot) => {
    // 排除当前正在编辑的实例
    if (isEdit.value && slot.instance_id === form.instance_id) {
      return false
    }
    return slot.day_of_week === targetDayStr && slot.start_time === period.startTime
  }

  return classroomOccupiedSlots.value.some(checkSlot) || teacherOccupiedSlots.value.some(checkSlot)
}

const isSelected = (dayIdx, periodId) => {
  return form.time_slots.some(slot => slot.day_of_week === dayIdx && slot.period === periodId)
}

const toggleTimeSlot = (dayIdx, periodId) => {
  if (!form.classroom_id || !form.semester_id) {
    ElMessage.warning('请先选择学期和教室')
    return
  }
  
  // 检查是否被其他课程占用
  // 这里需要区分：是被其他课程占用，还是被当前课程（编辑时）占用
  // 由于isOccupied目前没区分，所以如果显示已占，就不能点。
  // 这会导致编辑时无法取消选择（如果它被标记为已占）。
  // 必须解决这个问题。
  
  if (isOccupied(dayIdx, periodId)) {
    // 如果是已选状态，允许取消（说明是当前课程占用的，或者用户刚选的）
    // 但isOccupied返回true意味着数据库里有记录。
    // 如果是当前正在编辑的课程，数据库里肯定有记录。
    // 所以必须在isOccupied里排除当前课程。
    
    // 暂时先提示
    ElMessage.warning('该时间段已被占用')
    return
  }
  
  const index = form.time_slots.findIndex(slot => slot.day_of_week === dayIdx && slot.period === periodId)
  if (index > -1) {
    form.time_slots.splice(index, 1)
  } else {
    form.time_slots.push({ day_of_week: dayIdx, period: periodId })
  }
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
  form.time_slots = []
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(form, row)
  // 确保 teacher_ids 是数组
  form.teacher_ids = row.teachers.map(t => t.teacher_id)
  // 确保 time_slots 格式正确
  form.time_slots = row.time_slots.length > 0 ? [...row.time_slots] : []
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
      if (form.time_slots.length === 0) {
        ElMessage.warning('请至少选择一个上课时间段')
        return
      }
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

.time-selection-container {
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  padding: 10px;
  background: #fff;
  width: 100%;
}
.time-grid-header {
  display: grid;
  grid-template-columns: 80px repeat(7, 1fr);
  border-bottom: 1px solid #ebeef5;
  background: #f5f7fa;
}
.grid-cell-header {
  padding: 8px;
  text-align: center;
  font-weight: bold;
  color: #606266;
  border-right: 1px solid #ebeef5;
}
.grid-cell-header:last-child {
  border-right: none;
}
.time-grid-body {
  display: flex;
  flex-direction: column;
}
.grid-row {
  display: grid;
  grid-template-columns: 80px repeat(7, 1fr);
  border-bottom: 1px solid #ebeef5;
}
.grid-row:last-child {
  border-bottom: none;
}
.grid-cell-label {
  padding: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f9fafc;
  color: #909399;
  font-size: 12px;
  border-right: 1px solid #ebeef5;
}
.grid-cell {
  height: 40px;
  border-right: 1px solid #ebeef5;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  position: relative;
}
.grid-cell:last-child {
  border-right: none;
}
.grid-cell:hover:not(.is-disabled):not(.is-occupied) {
  background-color: #f0f9eb;
}
.grid-cell.is-selected {
  background-color: #67c23a;
  color: white;
}
.grid-cell.is-occupied {
  background-color: #f56c6c;
  color: white;
  cursor: not-allowed;
}
.grid-cell.is-disabled {
  background-color: #f5f7fa;
  cursor: not-allowed;
}
.occupied-text {
  font-size: 12px;
}
.time-legend {
  margin-top: 10px;
  display: flex;
  gap: 20px;
  justify-content: flex-end;
}
.legend-item {
  display: flex;
  align-items: center;
  font-size: 12px;
  color: #606266;
}
.color-box {
  width: 16px;
  height: 16px;
  margin-right: 6px;
  border-radius: 2px;
}
.color-box.occupied { background: #f56c6c; }
.color-box.selected { background: #67c23a; }
.color-box.available { background: #fff; border: 1px solid #dcdfe6; }

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
