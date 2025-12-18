<template>
  <div class="statistics">
    <div class="page-header">
      <div class="header-left">
        <h2>
          <el-icon><DataLine /></el-icon>
          选课统计
          <span class="text-muted">查看各课程的选课情况和统计数据</span>
        </h2>
      </div>
      <el-button @click="fetchStatistics" :loading="loading" icon="Refresh">
        刷新数据
      </el-button>
    </div>

    <el-card shadow="hover" class="data-card">
      <div v-loading="loading">
        <!-- 统计表格 -->
        <el-table :data="statistics" stripe border style="width: 100%">
          <el-table-column type="index" label="序号" width="60" align="center" />
          <el-table-column prop="course_id" label="课程编号" width="120" align="center">
            <template #default="{ row }">
              <span class="mono-font">{{ row.course_id }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="course_name" label="课程名称" min-width="150">
            <template #default="{ row }">
              <span class="course-name">{{ row.course_name }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="department" label="开课院系" width="150" align="center" />
          
          <el-table-column label="名额设置" align="center">
            <el-table-column prop="quota_inner" label="对内" width="80" align="center" />
            <el-table-column prop="quota_outer" label="对外" width="80" align="center" />
            <el-table-column prop="total_quota" label="总计" width="80" align="center">
              <template #default="{ row }">
                <span class="total-quota">{{ row.total_quota }}</span>
              </template>
            </el-table-column>
          </el-table-column>

          <el-table-column label="已选人数" align="center">
            <el-table-column prop="enrolled_inner" label="对内" width="80" align="center">
              <template #default="{ row }">
                <el-tag type="success" size="small" effect="light">{{ row.enrolled_inner }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="enrolled_outer" label="对外" width="80" align="center">
              <template #default="{ row }">
                <el-tag type="warning" size="small" effect="light">{{ row.enrolled_outer }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="total_enrolled" label="总计" width="80" align="center">
              <template #default="{ row }">
                <el-tag type="primary" size="small" effect="light">{{ row.total_enrolled }}</el-tag>
              </template>
            </el-table-column>
          </el-table-column>

          <el-table-column label="选课率" width="180" align="center">
            <template #default="{ row }">
              <div class="progress-container">
                <el-progress 
                  :percentage="parseFloat(row.enrollment_rate)"
                  :color="getProgressColor(parseFloat(row.enrollment_rate))"
                  :format="formatProgress"
                />
              </div>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh, DataLine } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const statistics = ref([])

const fetchStatistics = async () => {
  loading.value = true
  try {
    const res = await request.get('/statistics/enrollment', { params: { semester_id: 4 } })
    statistics.value = res
  } catch (error) {
    console.error('获取统计数据失败:', error)
    ElMessage.error('获取统计数据失败')
  } finally {
    loading.value = false
  }
}

const getProgressColor = (percentage) => {
  if (percentage >= 100) return '#F56C6C'
  if (percentage >= 80) return '#E6A23C'
  return '#67C23A'
}

const formatProgress = (percentage) => {
  return `${percentage}%`
}

onMounted(() => {
  fetchStatistics()
})
</script>

<style scoped>
.statistics {
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

.data-card {
  border: none;
}

.mono-font {
  font-family: monospace;
  color: #606266;
}

.course-name {
  font-weight: bold;
  color: #303133;
}

.total-quota {
  font-weight: bold;
}

.progress-container {
  padding: 0 10px;
}
</style>
