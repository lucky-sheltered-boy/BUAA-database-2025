import { defineStore } from 'pinia'
import { ref } from 'vue'
import request from '@/utils/request'

export const useSemesterStore = defineStore('semester', () => {
  // 当前学期ID (默认为4 - 2024-2025春季学期)
  const currentSemesterId = ref(4)
  const semesters = ref([])

  // 获取所有学期
  const fetchSemesters = async () => {
    try {
      // 这里可以调用后端API获取学期列表
      // 暂时使用硬编码数据
      semesters.value = [
        { id: 1, name: '2023-2024秋季学期' },
        { id: 2, name: '2024-2025秋季学期' },
        { id: 3, name: '2024-2025春季学期' },
        { id: 4, name: '2025-2026春季学期' }
      ]
    } catch (error) {
      console.error('获取学期列表失败:', error)
    }
  }

  // 切换学期
  const setSemester = (semesterId) => {
    currentSemesterId.value = semesterId
    localStorage.setItem('currentSemesterId', semesterId)
  }

  // 初始化
  const init = () => {
    const saved = localStorage.getItem('currentSemesterId')
    if (saved) {
      currentSemesterId.value = parseInt(saved)
    }
    fetchSemesters()
  }

  return {
    currentSemesterId,
    semesters,
    fetchSemesters,
    setSemester,
    init
  }
})
