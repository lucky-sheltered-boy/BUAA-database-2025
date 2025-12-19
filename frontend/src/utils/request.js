import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'

// 创建axios实例
const request = axios.create({
  baseURL: '/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
request.interceptors.request.use(
  config => {
    const authStore = useAuthStore()
    // 添加token
    if (authStore.token) {
      config.headers.Authorization = `Bearer ${authStore.token}`
    }
    return config
  },
  error => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
request.interceptors.response.use(
  response => {
    const res = response.data
    
    // 成功响应
    if (res.success) {
      // 统一返回后端 ResponseModel 的 data 字段
      return res.data
    }
    
    // 业务错误
    ElMessage.error(res.message || '操作失败')
    return Promise.reject(new Error(res.message || '操作失败'))
  },
  error => {
    console.error('响应错误:', error)
    
    // HTTP错误处理
    if (error.response) {
      const status = error.response.status
      const data = error.response.data
      let detail = data?.detail || error.message
      
      // 处理 Pydantic 验证错误 (422)
      if (status === 422 && Array.isArray(data?.detail)) {
        detail = data.detail.map(err => {
          const field = err.loc[err.loc.length - 1]
          return `${field}: ${err.msg}`
        }).join('; ')
      } else if (data?.message) {
        // 优先使用后端返回的 message 字段
        detail = data.message
      }

      // 将解析后的错误信息赋值给 error.message，供下游组件使用
      error.message = detail
      // 标记错误已被拦截器处理，防止重复弹窗
      error.isHandled = true
      
      switch (status) {
        case 401:
          // 如果是登录接口的 401，不进行登出操作，只显示错误信息
          if (error.config.url.includes('/auth/login')) {
            ElMessage.error(detail || '用户名或密码错误')
          } else {
            ElMessage.error('未授权，请重新登录')
            const authStore = useAuthStore()
            authStore.logout()
          }
          break
        case 403:
          ElMessage.error('拒绝访问')
          break
        case 404:
          ElMessage.error('请求资源不存在')
          break
        case 422:
          ElMessage.error(detail || '参数验证失败')
          break
        case 500:
          ElMessage.error('服务器错误')
          break
        default:
          ElMessage.error(detail || '请求失败')
      }
    } else if (error.request) {
      ElMessage.error('网络错误，请检查网络连接')
    } else {
      ElMessage.error(error.message || '请求失败')
    }
    
    return Promise.reject(error)
  }
)

export default request
