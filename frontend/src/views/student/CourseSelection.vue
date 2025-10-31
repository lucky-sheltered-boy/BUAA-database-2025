<template>
  <div class="course-selection">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>选课中心</span>
          <el-button type="primary" @click="fetchCourses" :loading="loading">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </template>

      <div v-loading="loading">
        <el-empty v-if="!loading && courses.length === 0" description="暂无可选课程" />
        
        <el-row :gutter="20" v-else>
          <el-col 
            v-for="course in courses" 
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
                  <span>课程编号: {{ course.course_id }}</span>
                </div>
                <div class="info-item">
                  <el-icon><TrophyBase /></el-icon>
                  <span>学分: {{ course.credit }}</span>
                </div>
                <div class="info-item">
                  <el-icon><OfficeBuilding /></el-icon>
                  <span>{{ course.department }}</span>
                </div>
                <div class="info-item">
                  <el-icon><Location /></el-icon>
                  <span>{{ course.building }} {{ course.room }}</span>
                </div>
                <div class="info-item">
                  <el-icon><User /></el-icon>
                  <span>剩余名额: {{ course.remaining_quota }}</span>
                </div>
              </div>

              <el-button 
                type="primary" 
                class="enroll-btn"
                :disabled="course.remaining_quota === 0"
                @click="handleEnroll(course)"
              >
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
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import request from '@/utils/request'
import {
  Refresh, Reading, TrophyBase, OfficeBuilding, Location, User
} from '@element-plus/icons-vue'

const authStore = useAuthStore()
const loading = ref(false)
const courses = ref([])

const fetchCourses = async () => {
  loading.value = true
  try {
    const res = await request.get(`/students/${authStore.userId}/available-courses`)
    if (res.success) {
      courses.value = res.data || []
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

.course-card {
  margin-bottom: 20px;
  transition: all 0.3s;
}

.course-card:hover {
  transform: translateY(-4px);
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
}

.course-info {
  margin-bottom: 15px;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  font-size: 13px;
  color: #606266;
}

.enroll-btn {
  width: 100%;
}
</style>
