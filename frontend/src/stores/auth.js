import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import router from '@/router'
import request from '@/utils/request'

export const useAuthStore = defineStore('auth', () => {
  // 状态
  const token = ref(localStorage.getItem('token') || '')
  const refreshToken = ref(localStorage.getItem('refreshToken') || '')
  const userInfo = ref(JSON.parse(localStorage.getItem('userInfo') || 'null'))

  // 计算属性
  const isLoggedIn = computed(() => !!token.value)
  const userRole = computed(() => userInfo.value?.role || '')
  const userName = computed(() => userInfo.value?.name || '')
  const userId = computed(() => userInfo.value?.user_id || 0)

  // 登录
  const login = async (username, password) => {
    try {
      const res = await request.post('/auth/login', {
        username,
        password
      })

      if (res) {
        // 保存token
        token.value = res.access_token
        refreshToken.value = res.refresh_token
        userInfo.value = res.user_info

        // 持久化到localStorage
        localStorage.setItem('token', res.access_token)
        localStorage.setItem('refreshToken', res.refresh_token)
        localStorage.setItem('userInfo', JSON.stringify(res.user_info))

        return res.user_info
      }
    } catch (error) {
      throw error
    }
  }

  // 登出
  const logout = () => {
    token.value = ''
    refreshToken.value = ''
    userInfo.value = null

    localStorage.removeItem('token')
    localStorage.removeItem('refreshToken')
    localStorage.removeItem('userInfo')

    router.push('/login')
  }

  // 检查登录状态
  const checkAuth = () => {
    if (!token.value || !userInfo.value) {
      return false
    }
    return true
  }

  // 刷新token
  const refresh = async () => {
    try {
      const res = await request.post('/auth/refresh', {
        refresh_token: refreshToken.value
      })

      if (res) {
        token.value = res.access_token
        refreshToken.value = res.refresh_token
        userInfo.value = res.user_info

        localStorage.setItem('token', res.access_token)
        localStorage.setItem('refreshToken', res.refresh_token)
        localStorage.setItem('userInfo', JSON.stringify(res.user_info))

        return true
      }
    } catch (error) {
      logout()
      return false
    }
  }

  return {
    token,
    userInfo,
    isLoggedIn,
    userRole,
    userName,
    userId,
    login,
    logout,
    checkAuth,
    refresh
  }
})
