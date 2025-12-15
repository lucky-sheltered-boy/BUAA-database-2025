# 高校智能排课选课管理系统 - 前端

基于 Vue 3 + Vite + Element Plus 构建的现代化前端应用。

## 技术栈

- **框架**: Vue 3 (Composition API)
- **构建工具**: Vite
- **UI库**: Element Plus
- **状态管理**: Pinia
- **路由**: Vue Router
- **HTTP客户端**: Axios
- **图标**: Element Plus Icons

## 功能特性

### 学生端
- ✅ 查看可选课程列表
- ✅ 在线选课/退课
- ✅ 查看个人课表
- ✅ 课程详细信息展示

### 教师端
- ✅ 查看个人授课安排
- ✅ 查看选课学生名单
- ✅ 课表可视化展示

### 教务端
- ✅ 系统概览统计
- ✅ 选课统计报表
- ✅ 数据可视化展示

## 快速开始

### 1. 安装依赖

```bash
cd frontend
npm install
```

### 2. 启动开发服务器

```bash
npm run dev
```

访问 http://localhost:5173

### 3. 构建生产版本

```bash
npm run build
```

构建产物位于 `dist/` 目录。

### 4. 预览生产构建

```bash
npm run preview
```

## 项目结构

```
frontend/
├── public/                # 静态资源
├── src/
│   ├── assets/           # 资源文件
│   ├── components/       # 公共组件
│   │   ├── CourseCard.vue       # 课程卡片
│   │   ├── ScheduleTable.vue    # 课表组件
│   │   └── StatisticsCard.vue   # 统计卡片
│   ├── views/            # 页面组件
│   │   ├── Login.vue            # 登录页
│   │   ├── student/
│   │   │   ├── Dashboard.vue    # 学生首页
│   │   │   ├── CourseSelection.vue  # 选课
│   │   │   └── MySchedule.vue   # 我的课表
│   │   ├── teacher/
│   │   │   ├── Dashboard.vue    # 教师首页
│   │   │   ├── MySchedule.vue   # 我的课表
│   │   │   └── StudentList.vue  # 学生名单
│   │   └── admin/
│   │       ├── Dashboard.vue    # 教务首页
│   │       └── Statistics.vue   # 统计报表
│   ├── router/           # 路由配置
│   │   └── index.js
│   ├── stores/           # Pinia状态管理
│   │   ├── auth.js              # 认证状态
│   │   └── semester.js          # 学期信息
│   ├── utils/            # 工具函数
│   │   ├── request.js           # Axios封装
│   │   └── constants.js         # 常量定义
│   ├── App.vue           # 根组件
│   └── main.js           # 入口文件
├── index.html
├── vite.config.js
└── package.json
```

## 环境配置

默认后端API地址为 `http://localhost:8000`。

如需修改，请编辑 `vite.config.js` 中的 proxy 配置：

```javascript
server: {
  proxy: {
    '/api': {
      target: 'http://your-backend-url',  // 修改为你的后端地址
      changeOrigin: true
    }
  }
}
```

## 测试账号

### 学生账号
- 学号: `2021001`
- 密码: `123456`
- 姓名: 张三

### 教师账号
- 工号: `T1001`
- 密码: `123456`
- 姓名: 张教授

### 教务账号
- 工号: `A001`
- 密码: `123456`
- 姓名: 教务1

## 主要功能说明

### 1. 登录认证
- JWT Token认证
- 自动Token刷新
- 路由守卫保护

### 2. 学生选课
- 可选课程列表展示
- 剩余名额实时显示
- 一键选课/退课
- 时间冲突自动检测
- 课表可视化展示

### 3. 教师查询
- 个人授课安排
- 学生选课名单
- 选课统计信息

### 4. 数据统计
- 系统概览面板
- 选课率统计图表
- 院系分布可视化

## 浏览器支持

- Chrome >= 87
- Firefox >= 78
- Safari >= 14
- Edge >= 88

## License

MIT License
