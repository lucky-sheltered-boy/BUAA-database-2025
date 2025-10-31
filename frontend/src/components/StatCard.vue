<!-- 统计卡片组件 -->
<template>
  <el-card class="stat-card">
    <div class="stat-content">
      <el-icon :size="iconSize" :color="color">
        <component :is="icon" />
      </el-icon>
      <div class="stat-info">
        <div class="stat-value">{{ value }}</div>
        <div class="stat-label">{{ label }}</div>
      </div>
    </div>
  </el-card>
</template>

<script setup>
const props = defineProps({
  icon: {
    type: [String, Object],
    required: true
  },
  color: {
    type: String,
    default: '#409EFF'
  },
  value: {
    type: [String, Number],
    required: true
  },
  label: {
    type: String,
    required: true
  },
  iconSize: {
    type: Number,
    default: 40
  }
})
</script>

<style scoped>
.stat-card {
  height: 100%;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 15px;
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
  line-height: 1;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}
</style>
