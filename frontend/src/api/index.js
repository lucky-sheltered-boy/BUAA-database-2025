import request from '@/utils/request'

/**
 * 注册
 * @param {object} data - 注册信息
 */
export function register(data) {
  return request.post('/auth/register', data)
}

/**
 * 获取院系列表
 */
export function getDepartments() {
  return request.get('/common/departments')
}

/**
 * 登录
 * @param {string} username - 用户名
 * @param {string} password - 密码
 */
export function login(username, password) {
  return request.post('/auth/login', { username, password })
}

/**
 * 刷新token
 * @param {string} refreshToken - 刷新令牌
 */
export function refreshToken(refreshToken) {
  return request.post('/auth/refresh', { refresh_token: refreshToken })
}

/**
 * 获取可选课程列表
 * @param {number} studentId - 学生ID
 */
export function getAvailableCourses(studentId) {
  return request.get(`/students/${studentId}/available-courses`)
}

/**
 * 学生选课
 * @param {number} studentId - 学生ID
 * @param {number} instanceId - 开课实例ID
 */
export function enrollCourse(studentId, instanceId) {
  return request.post(`/students/${studentId}/enroll`, { instance_id: instanceId })
}

/**
 * 学生退课
 * @param {number} studentId - 学生ID
 * @param {number} instanceId - 开课实例ID
 */
export function dropCourse(studentId, instanceId) {
  return request.post(`/students/${studentId}/drop`, { instance_id: instanceId })
}

/**
 * 获取学生课表
 * @param {number} studentId - 学生ID
 * @param {number} semesterId - 学期ID
 */
export function getStudentSchedule(studentId, semesterId) {
  return request.get(`/students/${studentId}/schedule`, {
    params: { semester_id: semesterId }
  })
}

/**
 * 获取教师课表
 * @param {number} teacherId - 教师ID
 * @param {number} semesterId - 学期ID
 */
export function getTeacherSchedule(teacherId, semesterId) {
  return request.get(`/teachers/${teacherId}/schedule`, {
    params: { semester_id: semesterId }
  })
}

/**
 * 获取选课学生名单
 * @param {number} teacherId - 教师ID
 * @param {number} instanceId - 开课实例ID
 */
export function getEnrolledStudents(teacherId, instanceId) {
  return request.get(`/teachers/${teacherId}/students`, {
    params: { instance_id: instanceId }
  })
}

/**
 * 获取选课统计
 * @param {number} semesterId - 学期ID
 */
export function getEnrollmentStatistics(semesterId) {
  return request.get('/statistics/enrollment', {
    params: { semester_id: semesterId }
  })
}

/**
 * 获取系统概览
 */
export function getSystemOverview() {
  return request.get('/statistics/overview')
}
