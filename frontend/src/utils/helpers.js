/**
 * 格式化日期时间
 * @param {Date|string} date - 日期对象或字符串
 * @param {string} format - 格式化模板
 * @returns {string} 格式化后的日期字符串
 */
export function formatDate(date, format = 'YYYY-MM-DD HH:mm:ss') {
  if (!date) return ''
  
  const d = new Date(date)
  if (isNaN(d.getTime())) return ''
  
  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const hours = String(d.getHours()).padStart(2, '0')
  const minutes = String(d.getMinutes()).padStart(2, '0')
  const seconds = String(d.getSeconds()).padStart(2, '0')
  
  return format
    .replace('YYYY', year)
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hours)
    .replace('mm', minutes)
    .replace('ss', seconds)
}

/**
 * 获取星期索引
 * @param {string} weekday - 星期字符串 (星期一、星期二等)
 * @returns {number} 星期索引 (1-7)
 */
export function getWeekdayIndex(weekday) {
  const map = {
    '星期一': 1,
    '星期二': 2,
    '星期三': 3,
    '星期四': 4,
    '星期五': 5,
    '星期六': 6,
    '星期日': 0
  }
  return map[weekday] || 0
}

/**
 * 解析时间段
 * @param {string} timeRange - 时间范围字符串 (如 "08:00-09:35")
 * @returns {object} { start: '08:00', end: '09:35' }
 */
export function parseTimeRange(timeRange) {
  if (!timeRange) return { start: '', end: '' }
  
  const [start, end] = timeRange.split('-')
  return { start: start?.trim() || '', end: end?.trim() || '' }
}

/**
 * 判断两个时间段是否冲突
 * @param {string} time1Start - 时间段1开始时间
 * @param {string} time1End - 时间段1结束时间
 * @param {string} time2Start - 时间段2开始时间
 * @param {string} time2End - 时间段2结束时间
 * @returns {boolean} 是否冲突
 */
export function isTimeConflict(time1Start, time1End, time2Start, time2End) {
  const t1s = parseTime(time1Start)
  const t1e = parseTime(time1End)
  const t2s = parseTime(time2Start)
  const t2e = parseTime(time2End)
  
  return !(t1e <= t2s || t2e <= t1s)
}

/**
 * 解析时间为分钟数
 * @param {string} time - 时间字符串 (如 "08:00")
 * @returns {number} 分钟数
 */
function parseTime(time) {
  if (!time) return 0
  const [hours, minutes] = time.split(':').map(Number)
  return hours * 60 + minutes
}

/**
 * 计算选课率
 * @param {number} enrolled - 已选人数
 * @param {number} quota - 总名额
 * @returns {string} 百分比字符串 (如 "75.5%")
 */
export function calculateRate(enrolled, quota) {
  if (!quota || quota === 0) return '0%'
  return ((enrolled / quota) * 100).toFixed(1) + '%'
}

/**
 * 防抖函数
 * @param {Function} fn - 要防抖的函数
 * @param {number} delay - 延迟时间(ms)
 * @returns {Function} 防抖后的函数
 */
export function debounce(fn, delay = 300) {
  let timer = null
  return function(...args) {
    if (timer) clearTimeout(timer)
    timer = setTimeout(() => {
      fn.apply(this, args)
    }, delay)
  }
}

/**
 * 节流函数
 * @param {Function} fn - 要节流的函数
 * @param {number} delay - 延迟时间(ms)
 * @returns {Function} 节流后的函数
 */
export function throttle(fn, delay = 300) {
  let last = 0
  return function(...args) {
    const now = Date.now()
    if (now - last >= delay) {
      last = now
      fn.apply(this, args)
    }
  }
}

/**
 * 深拷贝
 * @param {any} obj - 要拷贝的对象
 * @returns {any} 拷贝后的对象
 */
export function deepClone(obj) {
  if (obj === null || typeof obj !== 'object') return obj
  if (obj instanceof Date) return new Date(obj)
  if (obj instanceof Array) return obj.map(item => deepClone(item))
  
  const clonedObj = {}
  for (const key in obj) {
    if (obj.hasOwnProperty(key)) {
      clonedObj[key] = deepClone(obj[key])
    }
  }
  return clonedObj
}
