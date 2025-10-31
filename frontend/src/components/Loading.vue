<!-- 加载组件 -->
<template>
  <div class="loading-container" v-if="loading">
    <el-icon class="loading-icon" :size="size">
      <Loading />
    </el-icon>
    <p v-if="text" class="loading-text">{{ text }}</p>
  </div>
</template>

<script setup>
import { Loading } from '@element-plus/icons-vue'

defineProps({
  loading: {
    type: Boolean,
    default: true
  },
  text: {
    type: String,
    default: ''
  },
  size: {
    type: Number,
    default: 40
  }
})
</script>

<style scoped>
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.loading-icon {
  animation: rotate 1s linear infinite;
  color: #409EFF;
}

.loading-text {
  margin-top: 15px;
  font-size: 14px;
  color: #909399;
}

@keyframes rotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
