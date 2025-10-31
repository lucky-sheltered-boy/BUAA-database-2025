<template>
  <div class="statistics">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>选课统计</span>
          <el-button @click="fetchStatistics" :loading="loading">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </template>

      <div v-loading="loading">
        <!-- 统计表格 -->
        <el-table :data="statistics" stripe border>
          <el-table-column type="index" label="序号" width="60" />
          <el-table-column prop="course_id" label="课程编号" width="120" />
          <el-table-column prop="course_name" label="课程名称" min-width="150" />
          <el-table-column prop="department" label="开课院系" width="150" />
          
          <el-table-column label="名额设置" align="center">
            <el-table-column prop="quota_inner" label="对内" width="80" align="center" />
            <el-table-column prop="quota_outer" label="对外" width="80" align="center" />
            <el-table-column prop="total_quota" label="总计" width="80" align="center" />
          </el-table-column>

          <el-table-column label="已选人数" align="center">
            <el-table-column prop="enrolled_inner" label="对内" width="80" align="center">
              <template #default="{ row }">
                <el-tag type="success" size="small">{{ row.enrolled_inner }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="enrolled_outer" label="对外" width="80" align="center">
              <template #default="{ row }">
                <el-tag type="warning" size="small">{{ row.enrolled_outer }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="total_enrolled" label="总计" width="80" align="center">
              <template #default="{ row }">
                <el-tag type="primary" size="small">{{ row.total_enrolled }}</el-tag>
              </template>
            </el-table-column>
          </el-table-column>

          <el-table-column label="选课率" width="120" align="center">
            <template #default="{ row }">
              <el-progress 
                :percentage="parseFloat(row.enrollment_rate)"
                :color="getProgressColor(parseFloat(row.enrollment_rate))"
              >
                <span style="font-size: 12px;">{{ row.enrollment_rate }}</span>
              </el-progress>
            </template>
          </el-table-column>

          <el-table-column label="状态" width="100" align="center">
            <template #default="{ row }">
              <el-tag 
                :type="getStatusType(row.total_enrolled, row.total_quota)"
                size="small"
              >
                {{ getStatusText(row.total_enrolled, row.total_quota) }}
              </el-tag>
            </template>
          </el-table-column>
        </el-table>

        <!-- 统计汇总 -->
        <div class="summary" v-if="statistics.length > 0">
          <el-divider>统计汇总</el-divider>
          <el-row :gutter="20">
            <el-col :xs="24" :sm="12" :md="6">
              <div class="summary-card">
                <div class="summary-label">课程总数</div>
                <div class="summary-value">{{ statistics.length }}</div>
              </div>
            </el-col>
            <el-col :xs="24" :sm="12" :md="6">
              <div class="summary-card">
                <div class="summary-label">总名额</div>
                <div class="summary-value">{{ totalQuota }}</div>
              </div>
            </el-col>
            <el-col :xs="24" :sm="12" :md="6">
              <div class="summary-card">
                <div class="summary-label">已选人数</div>
                <div class="summary-value">{{ totalEnrolled }}</div>
              </div>
            </el-col>
            <el-col :xs="24" :sm="12" :md="6">
              <div class="summary-card">
                <div class="summary-label">平均选课率</div>
                <div class="summary-value">{{ averageRate }}%</div>
              </div>
            </el-col>
          </el-row>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useSemesterStore } from '@/stores/semester'
import request from '@/utils/request'
import { Refresh } from '@element-plus/icons-vue'

const semesterStore = useSemesterStore()

const loading = ref(false)
const statistics = ref([])

// 计算统计汇总
const totalQuota = computed(() => {
  return statistics.value.reduce((sum, item) => sum + item.total_quota, 0)
})

const totalEnrolled = computed(() => {
  return statistics.value.reduce((sum, item) => sum + item.total_enrolled, 0)
})

const averageRate = computed(() => {
  if (statistics.value.length === 0) return 0
  const sum = statistics.value.reduce((acc, item) => acc + parseFloat(item.enrollment_rate), 0)
  return (sum / statistics.value.length).toFixed(2)
})

const getProgressColor = (rate) => {
  if (rate < 50) return '#67C23A'
  if (rate < 80) return '#E6A23C'
  return '#F56C6C'
}

const getStatusType = (enrolled, quota) => {
  const rate = (enrolled / quota) * 100
  if (rate >= 100) return 'danger'
  if (rate >= 80) return 'warning'
  if (rate >= 50) return 'success'
  return 'info'
}

const getStatusText = (enrolled, quota) => {
  const rate = (enrolled / quota) * 100
  if (rate >= 100) return '已满'
  if (rate >= 80) return '紧张'
  if (rate >= 50) return '正常'
  return '充足'
}

const fetchStatistics = async () => {
  loading.value = true
  try {
    const res = await request.get(
      `/statistics/enrollment?semester_id=${semesterStore.currentSemesterId}`
    )
    
    if (res.success) {
      statistics.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取选课统计失败')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchStatistics()
})
</script>

<style scoped>
.statistics {
  max-width: 1600px;
  margin: 0 auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.summary {
  margin-top: 30px;
}

.summary-card {
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 8px;
  text-align: center;
  color: white;
  margin-bottom: 20px;
}

.summary-label {
  font-size: 14px;
  opacity: 0.9;
  margin-bottom: 10px;
}

.summary-value {
  font-size: 32px;
  font-weight: bold;
}

:deep(.el-progress__text) {
  font-size: 12px !important;
}
</style>
