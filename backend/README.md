# 高校智能排课选课管理系统 - 后端服务

基于 FastAPI + 华为云 TaurusDB 构建的排课选课管理系统后端服务。

## 技术栈

- **框架**: FastAPI 0.109.0
- **数据库**: 华为云 TaurusDB (MySQL 兼容)
- **数据库驱动**: PyMySQL (支持 TLS)
- **认证**: JWT (python-jose)
- **密码加密**: bcrypt (passlib)
- **日志**: loguru
- **测试**: pytest

## 项目结构

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI 应用入口
│   ├── config.py               # 配置管理
│   ├── database.py             # 数据库连接池
│   ├── dependencies.py         # 依赖注入
│   │
│   ├── api/                    # API 路由
│   │   ├── __init__.py
│   │   ├── auth.py             # 认证登录
│   │   ├── departments.py      # 院系管理
│   │   ├── classrooms.py       # 教室管理
│   │   ├── courses.py          # 课程管理
│   │   ├── semesters.py        # 学期管理
│   │   ├── users.py            # 用户管理
│   │   ├── instances.py        # 开课实例管理
│   │   ├── students.py         # 学生接口
│   │   ├── teachers.py         # 教师接口
│   │   └── statistics.py       # 统计报表
│   │
│   ├── models/                 # Pydantic 数据模型
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── department.py
│   │   ├── classroom.py
│   │   ├── course.py
│   │   ├── semester.py
│   │   ├── user.py
│   │   ├── instance.py
│   │   └── common.py           # 通用响应模型
│   │
│   ├── services/               # 业务逻辑层
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   ├── department_service.py
│   │   ├── enrollment_service.py
│   │   └── ...
│   │
│   ├── dal/                    # 数据访问层
│   │   ├── __init__.py
│   │   ├── base.py             # 基础 DAL 类
│   │   ├── department_dal.py
│   │   ├── user_dal.py
│   │   ├── instance_dal.py
│   │   └── stored_procedures.py # 存储过程调用
│   │
│   └── utils/                  # 工具函数
│       ├── __init__.py
│       ├── security.py         # JWT/密码工具
│       ├── logger.py           # 日志配置
│       └── exceptions.py       # 自定义异常
│
├── tests/                      # 测试
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_enrollment.py
│   └── ...
│
├── logs/                       # 日志目录
├── .env                        # 环境变量 (不提交)
├── .env.example                # 环境变量示例
├── requirements.txt            # 依赖
└── README.md
```

## 快速开始

### 1. 环境准备

```bash
# 创建虚拟环境
python -m venv venv

# 激活虚拟环境
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 2. 配置数据库

复制 `.env.example` 为 `.env` 并修改配置：

```bash
cp .env.example .env
```

编辑 `.env` 文件，填入您的 TaurusDB 连接信息：

```env
DB_HOST=your-taurusdb-endpoint.com
DB_PORT=3306
DB_USER=your_username
DB_PASSWORD=your_password
DB_NAME=course_selection_system

# 生产环境建议启用 SSL
DB_USE_SSL=True
DB_SSL_CA_PATH=/path/to/ca.pem
```

### 3. 初始化数据库

确保已在 TaurusDB 中执行以下脚本（按顺序）：

```bash
# 在 TaurusDB 中执行
SOURCE database/01_create_table.sql
SOURCE database/02_triggers.sql
SOURCE database/03_procedures.sql
SOURCE database/04_insert_data.sql
```

### 4. 运行服务

```bash
# 开发模式 (自动重载)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 生产模式
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

访问：
- **API 使用手册**: [API使用手册.md](./API使用手册.md) ⭐推荐阅读
- API 文档 (Swagger): http://localhost:8000/docs
- 备用文档 (ReDoc): http://localhost:8000/redoc
- 健康检查: http://localhost:8000/health

### 5. 测试

```bash
# 运行所有测试
pytest

# 运行特定测试
pytest tests/test_enrollment.py -v

# 生成覆盖率报告
pytest --cov=app --cov-report=html
```

## API 接口概览

### 认证接口
- `POST /api/auth/login` - 用户登录
- `POST /api/auth/refresh` - 刷新令牌

### 管理员接口 (教务)
- `GET/POST /api/departments` - 院系管理
- `GET/POST /api/classrooms` - 教室管理
- `GET/POST /api/courses` - 课程管理
- `GET/POST /api/semesters` - 学期管理
- `GET/POST /api/users` - 用户管理
- `POST /api/instances` - 创建开课实例
- `POST /api/instances/{id}/assign-teacher` - 分配教师
- `POST /api/instances/{id}/schedule` - 添加上课时间

### 学生接口
- `GET /api/students/{id}/available-courses` - 查询可选课程
- `POST /api/students/{id}/enroll` - 选课
- `POST /api/students/{id}/drop` - 退课
- `GET /api/students/{id}/schedule` - 查看课表

### 教师接口
- `GET /api/teachers/{id}/schedule` - 查看课表
- `GET /api/teachers/{id}/students` - 查看学生名单

### 统计接口
- `GET /api/statistics/enrollment` - 选课统计

## 数据库连接说明

### TaurusDB 连接特性

1. **连接池管理**: 使用 DBUtils 实现连接池，提高性能
2. **TLS 加密**: 生产环境强制使用 SSL/TLS 连接
3. **参数化查询**: 所有 SQL 使用参数化，防止注入
4. **存储过程调用**: 直接调用已有的 14 个存储过程
5. **触发器自动生效**: 选课/排课时触发器自动检查冲突

### 调用存储过程示例

```python
# 学生选课
cursor.callproc('sp_student_enroll', (student_id, instance_id, '@msg'))
cursor.execute('SELECT @msg')
message = cursor.fetchone()[0]

# 创建开课实例
cursor.callproc('sp_create_course_instance', 
    (course_id, classroom_id, semester_id, quota_inner, quota_outer, 
     '@instance_id', '@msg'))
```

## 安全建议

1. **JWT Secret**: 生产环境使用强随机密钥 (至少 32 字符)
2. **密码存储**: 使用 bcrypt 加密，不存储明文
3. **HTTPS**: 生产环境使用 HTTPS
4. **CORS**: 仅允许信任的前端域名
5. **SQL 注入**: 全部使用参数化查询
6. **TLS**: 数据库连接启用 SSL/TLS
7. **密钥管理**: 使用华为云 KMS 管理敏感信息

## 性能优化

1. **连接池**: 配置合理的连接池大小 (建议 5-20)
2. **索引**: 数据库已创建优化索引
3. **缓存**: 对不常变化的数据使用缓存 (Redis)
4. **异步**: 高并发场景考虑使用异步 I/O
5. **限流**: 对选课等关键接口做限流保护

## 并发处理

### 选课高并发策略

1. **数据库层**: 触发器 + SELECT FOR UPDATE 锁定
2. **应用层**: 重试机制处理死锁 (最多 3 次)
3. **排队机制**: 高峰期使用消息队列排队
4. **幂等性**: 防止重复提交

## 监控与日志

- **日志**: loguru 记录所有 API 调用和错误
- **慢查询**: 开启 TaurusDB 慢查询日志
- **指标**: 使用 Prometheus 监控请求量/错误率/延迟
- **告警**: 配置华为云告警规则

## 部署

### Docker 部署

```bash
# 构建镜像
docker build -t course-selection-backend .

# 运行容器
docker run -d -p 8000:8000 --env-file .env course-selection-backend
```

### 华为云部署

1. 将代码推送到华为云 CodeHub
2. 使用华为云容器服务 (CCE) 部署
3. 配置 VPC 与 TaurusDB 在同一网络
4. 使用华为云 Secrets Manager 管理密钥

## 常见问题

### Q: 连接 TaurusDB 超时?
A: 检查安全组规则，确保后端服务器 IP 在白名单中

### Q: 选课时出现死锁?
A: 已实现重试机制，正常情况下会自动重试

### Q: 如何启用 SSL 连接?
A: 下载 TaurusDB CA 证书，设置 `DB_USE_SSL=True` 和 `DB_SSL_CA_PATH`

## License

MIT License
