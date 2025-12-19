<template>
  <el-card class="course-card" shadow="hover">
    <div class="course-header">
      <div class="header-main">
        <h3 class="course-title" :title="course.course_name">{{ course.course_name }}</h3>
        <el-tag :type="tagType" size="small" effect="plain">
          {{ course.enroll_type || '本院系' }}
        </el-tag>
      </div>
      <div class="course-id">{{ course.course_id }}</div>
    </div>

    <div class="course-body">
      <div class="info-grid">
        <div class="info-item">
          <el-icon><TrophyBase /></el-icon>
          <span>{{ course.credit }} 学分</span>
        </div>
        <div class="info-item">
          <el-icon><OfficeBuilding /></el-icon>
          <span class="truncate" :title="course.department">{{ course.department }}</span>
        </div>
        <div class="info-item" v-if="course.building">
          <el-icon><Location /></el-icon>
          <span>{{ course.building }} {{ course.room }}</span>
        </div>
        <div class="info-item" v-if="showQuota">
          <el-icon><User /></el-icon>
          <span :class="{ 'text-danger': (course.remaining_quota || 0) < 5 }">
            剩余: {{ course.remaining_quota || 0 }}
          </span>
        </div>
      </div>
    </div>

    <div class="course-footer" v-if=".actions">
      <slot name="actions"></slot>
    </div>
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
  display: flex;
  flex-direction: column;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid var(--border-color-light);
}

.course-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--box-shadow-light);
  border-color: var(--primary-color-light);
}

.course-header {
  margin-bottom: 16px;
}

.header-main {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 8px;
  margin-bottom: 4px;
}

.course-title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.course-id {
  font-size: 12px;
  color: var(--text-placeholder);
  font-family: monospace;
}

.course-body {
  flex: 1;
  padding: 12px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: var(--text-regular);
}

.info-item .el-icon {
  color: var(--text-secondary);
}

.truncate {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.text-danger {
  color: var(--danger-color);
  font-weight: 500;
}

.course-footer {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid var(--border-color-lighter);
  display: flex;
  justify-content: flex-end;
}
</style>
