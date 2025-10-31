export default {
  // 当前学期ID (默认为4)
  currentSemesterId: 4,
  
  // API基础路径
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL || '/api',
  
  // Token存储键
  tokenKey: 'token',
  refreshTokenKey: 'refreshToken',
  userInfoKey: 'userInfo',
  
  // 页面标题
  pageTitle: '高校智能排课选课管理系统',
  
  // 分页配置
  pagination: {
    pageSize: 10,
    pageSizes: [10, 20, 50, 100]
  }
}
