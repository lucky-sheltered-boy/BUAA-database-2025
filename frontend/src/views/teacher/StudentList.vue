<template>
  <div class="student-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>学生名单</span>
          <el-button @click="fetchStudents" :loading="loading">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </template>

      <div v-loading="loading">
        <el-table :data="students" stripe>
          <el-table-column type="index" label="序号" width="60" />
          <el-table-column prop="student_number" label="学号" width="120" />
          <el-table-column prop="name" label="姓名" width="100" />
          <el-table-column prop="department" label="院系" />
          <el-table-column prop="enroll_type" label="选课类型" width="100">
            <template #default="{ row }">
              <el-tag :type="row.enroll_type === '本院系' ? 'success' : 'warning'" size="small">
                {{ row.enroll_type }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="enroll_time" label="选课时间" width="180" />
        </el-table>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import request from '@/utils/request'
import { Refresh } from '@element-plus/icons-vue'

const route = useRoute()
const authStore = useAuthStore()

const loading = ref(false)
const students = ref([])
const instanceId = ref(route.params.instanceId)

const fetchStudents = async () => {
  loading.value = true
  try {
    const res = await request.get(
      `/teachers/${authStore.userId}/students?instance_id=${instanceId.value}`
    )
    
    if (res.success) {
      students.value = res.data || []
    }
  } catch (error) {
    ElMessage.error('获取学生名单失败')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchStudents()
})
</script>

<style scoped>
.student-list {
  max-width: 1400px;
  margin: 0 auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
