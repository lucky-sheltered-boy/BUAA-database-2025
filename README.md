# 高校智能排课选课管理系统

**BUAA Database Course Project 2025**

## 📚 项目简介

这是一个功能完整的高校智能排课选课管理系统，基于现代化技术栈开发，包含完整的数据库设计、后端API和前端界面。

### 核心特性

- ✨ **周次灵活管理** - 支持全学期、前后8周、单双周等多种排课模式
- ✨ **智能冲突检测** - 11个触发器自动检测教室/教师/学生时间冲突
- ✨ **跨院系选课** - 自动区分对内/对外名额，支持院系间课程共享
- ✨ **三端分离** - 学生端、教师端、教务端功能清晰
- ✨ **现代化界面** - 基于Vue 3 + Element Plus的响应式UI

## 🏗 技术架构

### 数据库层
- **数据库**: MySQL 8.0 / 华为云 TaurusDB
- **表结构**: 10张表 + 3个视图
- **触发器**: 11个（智能冲突检测）
- **存储过程**: 14个（业务逻辑封装）
- **测试数据**: 5个院系、19门课程、39个用户

### 后端层
- **框架**: FastAPI 0.115.0
- **数据库驱动**: PyMySQL + DBUtils
- **认证**: JWT Token
- **API接口**: 11个核心接口
- **文档**: 自动生成Swagger UI

### 前端层
- **框架**: Vue 3.4 + Vite 5
- **UI库**: Element Plus 2.6
- **状态管理**: Pinia 2.1
- **路由**: Vue Router 4
- **HTTP客户端**: Axios

## 📁 项目结构

```
BUAA-database-2025/
├── database/              # 数据库脚本
│   ├── 01_create_table.sql     # 建表脚本
│   ├── 02_triggers.sql         # 触发器脚本
│   ├── 03_procedures.sql       # 存储过程脚本
│   ├── 04_insert_data.sql      # 测试数据
│   ├── ER图.md                 # ER图说明
│   └── README.md               # 详细使用指南
│
├── backend/               # FastAPI后端
│   ├── app/
│   │   ├── api/               # API路由
│   │   ├── dal/               # 数据访问层
│   │   ├── models/            # 数据模型
│   │   ├── utils/             # 工具函数
│   │   ├── config.py          # 配置管理
│   │   ├── database.py        # 数据库连接池
│   │   └── main.py            # 应用入口
│   ├── tests/                 # 测试文件
│   ├── .env.example           # 环境变量示例
│   ├── API使用手册.md         # API文档
│   ├── 后端实现说明.md        # 技术实现说明
│   ├── requirements.txt       # Python依赖
│   └── test_db_connection.py  # 数据库连接测试
│
├── frontend/              # Vue前端
│   ├── src/
│   │   ├── views/             # 页面组件
│   │   │   ├── student/       # 学生端
│   │   │   ├── teacher/       # 教师端
│   │   │   └── admin/         # 教务端
│   │   ├── components/        # 公共组件
│   │   ├── stores/            # 状态管理
│   │   ├── router/            # 路由配置
│   │   ├── api/               # API封装
│   │   ├── utils/             # 工具函数
│   │   ├── config/            # 配置文件
│   │   ├── App.vue
│   │   └── main.js
│   ├── .env.example           # 环境变量示例
│   ├── package.json
│   ├── vite.config.js
│   ├── README.md
│   └── 启动说明.md
│
├── docs/                  # 文档
│   ├── 设计文档.md            # 系统设计报告（810行）
│   ├── 大作业要求.md          # 课程要求
│   └── 界面美化说明.md        # 界面美化更新日志
│
├── 启动前端.ps1           # 前端快速启动脚本
├── 启动后端.ps1           # 后端快速启动脚本
└── README.md              # 本文件
```

## 🚀 快速开始

### 1. 数据库部署

```bash
# 进入数据库目录
cd database

# 在MySQL中按顺序执行
SOURCE 01_create_table.sql
SOURCE 02_triggers.sql
SOURCE 03_procedures.sql
SOURCE 04_insert_data.sql
```

**提示**: 详细说明请查看 [database/README.md](database/README.md)

### 2. 后端启动

```bash
# 进入后端目录
cd backend

# 安装依赖
pip install -r requirements.txt

# 配置数据库连接
cp .env.example .env
# 编辑 .env 文件，填入数据库连接信息

# 启动服务
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

访问 http://localhost:8000/docs 查看API文档

### 3. 前端启动

```bash
# 进入前端目录
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

访问 http://localhost:5173

## 👥 测试账号

### 学生账号
- 学号: `2021001` | 密码: `123456` | 姓名: 张三

### 教师账号
- 工号: `T1001` | 密码: `123456` | 姓名: 张教授

### 教务账号
- 工号: `A001` | 密码: `123456` | 姓名: 教务1

## 🎯 功能展示

### 学生端
- 📊 个人选课统计面板
- 📚 可选课程列表（实时剩余名额）
- ✅ 在线选课/退课
- 📅 个人课表（列表+表格双视图）
- ⚠️ 时间冲突自动检测

### 教师端
- 📊 授课统计面板
- 📅 授课课表展示
- 📈 选课率可视化
- 👥 学生名单查看
- 🏷️ 本院系/跨院系学生区分

### 教务端
- 📊 系统数据概览
- 👥 用户角色统计
- 📈 选课统计报表
- 📉 选课率分析
- 📋 名额使用情况

## 📊 数据库设计亮点

### 1. 周次灵活管理
支持多种排课模式：
- 全学期课程（1-16周）
- 前半学期（1-8周）/ 后半学期（9-16周）
- 单周/双周课程（实验课分组）
- 自定义周次范围

### 2. 智能冲突检测
11个触发器实现：
- ✅ 教室时间冲突检测
- ✅ 教师时间冲突检测
- ✅ 学生时间冲突检测
- ✅ 选课名额限制
- ✅ 教室容量检测
- ✅ 选课时间窗口检测

### 3. 跨院系选课
- 对内名额（本院系学生）
- 对外名额（外院系学生）
- 自动计数和更新

## 📖 文档资源

- **数据库使用指南**: [database/README.md](database/README.md)
- **后端API文档**: [backend/API使用手册.md](backend/API使用手册.md)
- **前端启动说明**: [frontend/启动说明.md](frontend/启动说明.md)
- **系统设计文档**: [docs/设计文档.md](docs/设计文档.md)

## 🔧 常见问题

### Q: 数据库连接失败？
A: 检查华为云TaurusDB的IP白名单配置，需要添加您的公网IP

### Q: 前端请求跨域？
A: Vite已配置代理，确保后端运行在 http://localhost:8000

### Q: 选课失败提示冲突？
A: 这是正常的业务逻辑，触发器会检测：
- 时间冲突
- 名额已满
- 选课时间窗口
- 重复选课

## 🎓 项目亮点总结

1. **完整的三层架构** - 数据库 → 后端API → 前端UI
2. **现代化技术栈** - FastAPI + Vue 3 + Element Plus
3. **智能业务规则** - 触发器自动检测冲突
4. **灵活的周次管理** - 支持多种排课模式
5. **完善的文档** - 数据库、后端、前端文档齐全
6. **响应式设计** - 支持桌面和移动端
7. **角色权限控制** - JWT认证 + 路由守卫

## 📄 License

MIT License

## 👨‍💻 开发团队

北京航空航天大学 - 数据库系统原理课程组

---

**祝使用愉快！如有问题欢迎提Issue** 🎉