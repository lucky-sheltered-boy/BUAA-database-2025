<template>
  <div class="student-list">
    <el-card class="main-card" shadow="never">
      <template #header>
        <div class="card-header">
          <div class="header-left">
            <el-button @click="router.back()" circle plain>
              <el-icon><ArrowLeft /></el-icon>
            </el-button>
            <span class="header-title">学生名单</span>
            <el-tag type="info" effect="plain" class="count-tag">
              共 {{ students.length }} 人
            </el-tag>
          </div>
          <div class="header-actions">
            <el-button type="primary" @click="fetchStudents" :loading="loading" plain>
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
            <el-button type="success" @click="exportData" plain>
              <el-icon><Download /></el-icon>
              导出名单
            </el-button>
          </div>
        </div>
      </template>

      <div class="table-container" v-loading="loading">
        <el-table 
          :data="students" 
          stripe 
          style="width: 100%"
          :header-cell-style="{ background: '#f5f7fa', color: '#606266' }"
        >
          <el-table-column type="index" label="序号" width="80" align="center" />
          
          <el-table-column prop="student_number" label="学号" width="150" sortable>
            <template #default="{ row }">
              <span class="mono-font">{{ row.student_number }}</span>
            </template>
          </el-table-column>
          
          <el-table-column prop="name" label="姓名" width="120">
            <template #default="{ row }">
              <div class="user-cell">
                <el-avatar :size="24" class="user-avatar">{{ row.name.charAt(0) }}</el-avatar>
                <span>{{ row.name }}</span>
              </div>
            </template>
          </el-table-column>
          
          <el-table-column prop="department_name" label="院系" min-width="180" sortable />
          
          <el-table-column prop="enrollment_time" label="选课时间" width="180" sortable>
            <template #default="{ row }">
              {{ formatTime(row.enrollment_time) }}
            </template>
          </el-table-column>

          <el-table-column label="状态" width="100" align="center">
            <template #default>
              <el-tag type="success" size="small" effect="light">已选课</el-tag>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'
import request from '@/utils/request'
import { ArrowLeft, Refresh, Download } from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const students = ref([])
const instanceId = route.params.instanceId

const fetchStudents = async () => {
  if (!instanceId) {
    ElMessage.warning('未指定课程')
    return
  }

  loading.value = true
  try {
    const res = await request.get(`/teachers/${authStore.userId}/students`, { params: { instance_id: instanceId } })
    students.value = res
  } catch (error) {
    console.error('获取学生名单失败:', error)
    ElMessage.error('获取学生名单失败')
  } finally {
    loading.value = false
  }
}

const formatTime = (timeStr) => {
  if (!timeStr) return '-'
  return new Date(timeStr).toLocaleString()
}

const exportData = () => {
  // 简单的CSV导出实现
  const headers = ['学号', '姓名', '院系', '选课时间']
  const data = students.value.map(s => [
    s.student_number,
    s.name,
    s.department_name,
    formatTime(s.enrollment_time)
  ])
  
  const csvContent = [
    headers.join(','),
    ...data.map(row => row.join(','))
  ].join('\n')
  
  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = `学生名单_${new Date().toLocaleDateString()}.csv`
  link.click()
}

onMounted(() => {
  fetchStudents()
})
</script>

<style scoped>
.student-list {
  padding-bottom: 20px;
}

.main-card {
  border: none;
  background: transparent;
}

.main-card :deep(.el-card__header) {
  background: #fff;
  border-radius: 8px 8px 0 0;
  border-bottom: 1px solid #ebeef5;
  padding: 16px 24px;
}

.main-card :deep(.el-card__body) {
  background: #fff;
  border-radius: 0 0 8px 8px;
  padding: 0;
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

.header-title {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.table-container {
  padding: 20px;
}

.mono-font {
  font-family: monospace;
  color: #606266;
}

.user-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.user-avatar {
  background-color: var(--primary-color-light);
  color: var(--primary-color);
  font-size: 12px;
}
</style>
