<template>
  <div class="course-selection">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>选课中心</span>
          <div class="header-actions">
            <el-tag :type="statsTagType" effect="plain" size="large">
              共 {{ filteredCourses.length }} 门课程
            </el-tag>
            <el-button type="primary" @click="fetchCourses" :loading="loading">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
          </div>
        </div>
      </template>

      <!-- 标签页切换 -->
      <el-tabs v-model="activeTab" @tab-change="handleTabChange">
        <el-tab-pane label="全部课程" name="all">
          <template #label>
            <span class="tab-label">
              <el-icon><Grid /></el-icon>
              全部课程
              <el-badge :value="courses.length" :max="99" class="tab-badge" />
            </span>
          </template>
        </el-tab-pane>
        
        <el-tab-pane label="本专业课程" name="internal">
          <template #label>
            <span class="tab-label">
              <el-icon><School /></el-icon>
              本专业课程
              <el-badge :value="internalCourses.length" :max="99" type="success" class="tab-badge" />
            </span>
          </template>
        </el-tab-pane>
        
        <el-tab-pane label="跨专业课程" name="external">
          <template #label>
            <span class="tab-label">
              <el-icon><Connection /></el-icon>
              跨专业课程
              <el-badge :value="externalCourses.length" :max="99" type="warning" class="tab-badge" />
            </span>
          </template>
        </el-tab-pane>
      </el-tabs>

      <div v-loading="loading">
        <el-empty 
          v-if="!loading && filteredCourses.length === 0" 
          :description="emptyDescription"
        />
        
        <el-row :gutter="20" v-else>
          <el-col 
            v-for="course in filteredCourses" 
            :key="course.instance_id"
            :xs="24" :sm="12" :md="8" :lg="6"
          >
            <el-card class="course-card" shadow="hover">
              <div class="course-header">
                <h3>{{ course.course_name }}</h3>
                <el-tag :type="course.enroll_type === '本院系' ? 'success' : 'warning'">
                  {{ course.enroll_type }}
                </el-tag>
              </div>

              <div class="course-info">
                <div class="info-item">
                  <el-icon><Reading /></el-icon>
                  <span>{{ course.course_id }}</span>
                </div>
                <div class="info-item">
                  <el-icon><TrophyBase /></el-icon>
                  <span>{{ course.credit }} 学分</span>
                </div>
                <div class="info-item">
                  <el-icon><OfficeBuilding /></el-icon>
                  <span>{{ course.department }}</span>
                </div>
                <div class="info-item">
                  <el-icon><Location /></el-icon>
                  <span>{{ course.building }} {{ course.room }}</span>
                </div>
                <div class="info-item quota-item">
                  <el-icon><User /></el-icon>
                  <span :class="{'quota-low': course.remaining_quota < 5}">
                    剩余: {{ course.remaining_quota }}/{{ course.total_quota }}
                  </span>
                  <el-progress 
                    :percentage="getQuotaPercentage(course)" 
                    :color="getQuotaColor(course)"
                    :show-text="false"
                    style="flex: 1; margin-left: 8px"
                  />
                </div>
              </div>

              <el-button 
                type="primary" 
                class="enroll-btn"
                :disabled="course.remaining_quota === 0"
                @click="handleEnroll(course)"
              >
                <el-icon><CirclePlus /></el-icon>
                {{ course.remaining_quota === 0 ? '名额已满' : '选课' }}
              </el-button>
            </el-card>
          </el-col>
        </el-row>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import request from '@/utils/request'
import {
  Refresh, Reading, TrophyBase, OfficeBuilding, Location, User,
  Grid, School, Connection, CirclePlus
} from '@element-plus/icons-vue'

const authStore = useAuthStore()
const loading = ref(false)
const courses = ref([])
const activeTab = ref('all')

// 计算属性：本专业课程
const internalCourses = computed(() => {
  return courses.value.filter(c => c.enroll_type === '本院系')
})

// 计算属性：跨专业课程
const externalCourses = computed(() => {
  return courses.value.filter(c => c.enroll_type === '跨院系')
})

// 计算属性：根据标签页筛选课程
const filteredCourses = computed(() => {
  switch (activeTab.value) {
    case 'internal':
      return internalCourses.value
    case 'external':
      return externalCourses.value
    default:
      return courses.value
  }
})

// 计算属性：空数据描述
const emptyDescription = computed(() => {
  switch (activeTab.value) {
    case 'internal':
      return '暂无本专业可选课程'
    case 'external':
      return '暂无跨专业可选课程'
    default:
      return '暂无可选课程'
  }
})

// 计算属性：统计标签类型
const statsTagType = computed(() => {
  if (filteredCourses.value.length === 0) return 'info'
  if (activeTab.value === 'internal') return 'success'
  if (activeTab.value === 'external') return 'warning'
  return 'primary'
})

// 计算名额百分比
const getQuotaPercentage = (course) => {
  if (!course.total_quota) return 0
  return Math.round((course.remaining_quota / course.total_quota) * 100)
}

// 获取名额进度条颜色
const getQuotaColor = (course) => {
  const percentage = getQuotaPercentage(course)
  if (percentage > 50) return '#67C23A'
  if (percentage > 20) return '#E6A23C'
  return '#F56C6C'
}

// 标签页切换处理
const handleTabChange = (tabName) => {
  console.log('切换到标签页:', tabName)
}

const fetchCourses = async () => {
  loading.value = true
  try {
    const res = await request.get(`/students/${authStore.userId}/available-courses`)
    if (res.success) {
      courses.value = res.data || []
      ElMessage.success(`加载了 ${courses.value.length} 门课程`)
    }
  } catch (error) {
    ElMessage.error('获取课程列表失败')
  } finally {
    loading.value = false
  }
}

const handleEnroll = (course) => {
  ElMessageBox.confirm(
    `确定要选择《${course.course_name}》吗？`,
    '选课确认',
    {
      confirmButtonText: '确定选课',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(async () => {
    try {
      const res = await request.post(
        `/students/${authStore.userId}/enroll`,
        { instance_id: course.instance_id }
      )
      
      if (res.success) {
        ElMessage.success(res.message || '选课成功')
        fetchCourses() // 刷新列表
      }
    } catch (error) {
      const message = error.response?.data?.detail || '选课失败'
      ElMessage.error(message)
    }
  })
}

onMounted(() => {
  fetchCourses()
})
</script>

<style scoped>
.course-selection {
  max-width: 1400px;
  margin: 0 auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 12px;
  align-items: center;
}

/* 标签页样式 */
.tab-label {
  display: flex;
  align-items: center;
  gap: 6px;
}

.tab-badge {
  margin-left: 4px;
}

:deep(.el-tabs__nav-wrap) {
  margin-bottom: 20px;
}

:deep(.el-tabs__item) {
  font-size: 15px;
  font-weight: 500;
}

/* 课程卡片 */
.course-card {
  margin-bottom: 20px;
  transition: all 0.3s;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.course-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.course-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
  padding-bottom: 12px;
  border-bottom: 1px solid #ebeef5;
}

.course-header h3 {
  margin: 0;
  font-size: 16px;
  color: #303133;
  flex: 1;
  line-height: 1.4;
}

.course-info {
  margin-bottom: 15px;
  flex: 1;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  font-size: 13px;
  color: #606266;
}

.quota-item {
  background: #f5f7fa;
  padding: 6px 10px;
  border-radius: 4px;
  margin-top: 8px;
}

.quota-low {
  color: #F56C6C;
  font-weight: 600;
}

.enroll-btn {
  width: 100%;
  margin-top: auto;
}

/* 响应式 */
@media (max-width: 768px) {
  .header-actions {
    flex-direction: column;
    gap: 8px;
  }
  
  .tab-label {
    font-size: 13px;
  }
}
</style>
