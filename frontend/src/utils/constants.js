// 星期映射
export const WEEKDAYS = {
  '星期一': 1,
  '星期二': 2,
  '星期三': 3,
  '星期四': 4,
  '星期五': 5,
  '星期六': 6,
  '星期日': 0
}

export const WEEKDAY_NAMES = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']

// 时间段配置
export const TIME_SLOTS = [
  { label: '第1-2节', value: 1, time: '08:00-09:35' },
  { label: '第3-4节', value: 2, time: '10:00-11:35' },
  { label: '第5-6节', value: 3, time: '14:00-15:35' },
  { label: '第7-8节', value: 4, time: '16:00-17:35' },
  { label: '第9-10节', value: 5, time: '19:00-20:35' }
]

// 用户角色
export const USER_ROLES = {
  STUDENT: '学生',
  TEACHER: '教师',
  ADMIN: '教务'
}

// 选课类型
export const ENROLL_TYPES = {
  INNER: '本院系',
  OUTER: '跨院系'
}

// 周次类型
export const WEEK_TYPES = {
  ALL: '全部',
  ODD: '单周',
  EVEN: '双周'
}

// 颜色主题
export const COLORS = {
  primary: '#409EFF',
  success: '#67C23A',
  warning: '#E6A23C',
  danger: '#F56C6C',
  info: '#909399'
}
