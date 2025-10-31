<!-- 课程卡片组件 -->
<template>
  <el-card class="course-card" shadow="hover">
    <div class="course-header">
      <h3>{{ course.course_name }}</h3>
      <el-tag :type="tagType">
        {{ course.enroll_type || '本院系' }}
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
      <div class="info-item" v-if="course.building">
        <el-icon><Location /></el-icon>
        <span>{{ course.building }} {{ course.room }}</span>
      </div>
      <div class="info-item" v-if="showQuota">
        <el-icon><User /></el-icon>
        <span>剩余: {{ course.remaining_quota || 0 }}</span>
      </div>
    </div>

    <slot name="actions"></slot>
  </el-card>
</template>

<script setup>
import { computed } from 'vue'
import { Reading, TrophyBase, OfficeBuilding, Location, User } from '@element-plus/icons-vue'

const props = defineProps({
  course: {
    type: Object,
    required: true
  },
  showQuota: {
    type: Boolean,
    default: true
  }
})

const tagType = computed(() => {
  return props.course.enroll_type === '本院系' ? 'success' : 'warning'
})
</script>

<style scoped>
.course-card {
  height: 100%;
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
</style>
