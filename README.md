# 高校智能排课选课管理系统（数据库大作业）

本仓库是一个面向“排课/选课”场景的数据库应用系统示例，包含：
- **数据库脚本**（表 / 视图 / 触发器 / 存储过程 / 测试数据）
- **后端服务**（FastAPI，提供 REST API）
- **前端应用**（Vue 3 + Vite + Element Plus）

> 建议先按顺序初始化数据库，再启动后端与前端。

## 目录结构

```text
.
├── backend/                 # FastAPI 后端
├── frontend/                # Vue3 前端
├── database/                # SQL 脚本（建表/触发器/存储过程/数据）
├── docs/                    # 设计/实现报告与课程要求
├── resources/               # 其他资源
├── backend.ps1              # Windows 一键启动后端脚本
└── frontend.ps1             # Windows 一键启动前端脚本
```

## 技术栈

- **数据库**：MySQL 8.0 兼容（如华为云 GaussDB(for MySQL) / TaurusDB 等）
- **后端**：FastAPI + Uvicorn，PyMySQL + DBUtils
- **前端**：Vue 3 + Vite + Element Plus + Pinia + Vue Router

## 环境要求

- **Python**：3.8+（建议 3.10/3.11）
- **Node.js**：建议 v18+
- **数据库**：MySQL 8.0 兼容实例（本地或云端）

## 快速开始（推荐）

### 1) 初始化数据库

在你的 MySQL 兼容数据库中，按顺序执行以下脚本（位于 `database/`）：

1. `database/01_create_table.sql`（表结构 + 视图）
2. `database/02_triggers.sql`（触发器）
3. `database/03_procedures.sql`（存储过程）
4. `database/04_insert_data.sql`（测试数据）

数据库侧的更详细说明与演示 SQL：
- 参见 `database/README.md`
- ER 图：`database/ER图.md`

### 2) 启动后端

#### 方式 A：一键脚本（Windows / PowerShell）
在项目根目录执行：

```powershell
.\backend.ps1
```

脚本会：创建 venv → 安装依赖 → 启动服务。

#### 方式 B：手动启动

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

后端启动后访问：
- API 文档（Swagger）：http://localhost:8000/docs
- ReDoc：http://localhost:8000/redoc

> 后端需要数据库连接配置：请在 `backend/` 下按 `backend/.env.example` 复制为 `.env` 并填写连接信息。

更多后端细节：
- `backend/README.md`
- `backend/API使用手册.md`
- `backend/后端实现说明.md`

### 3) 启动前端

#### 方式 A：一键脚本（Windows / PowerShell）
在项目根目录执行：

```powershell
.\frontend.ps1
```

#### 方式 B：手动启动

```powershell
cd frontend
npm install
npm run dev
```

前端默认地址：
- http://localhost:5173

前端默认通过 Vite proxy 访问后端：
- 后端请保持运行在 `http://localhost:8000`
- 如需修改代理，请查看 `frontend/vite.config.js`

## 测试账号（内置测试数据）

- 学生：`2021001 / 123456`
- 教师：`T1001 / 123456`
- 教务：`A001 / 123456`

> 账号与数据由 `database/04_insert_data.sql` 提供；若你改动了初始化数据，账号可能不同。

## 后端测试（可选）

在后端虚拟环境中执行：

```powershell
cd backend
.\venv\Scripts\Activate.ps1
pytest
```

## 常见问题

- **前端能打开但接口报错/无数据**：确认后端已启动（8000 端口），并确认数据库脚本已执行且 `.env` 配置正确。
- **PowerShell 脚本无法运行**：可在管理员 PowerShell 中临时允许脚本执行：

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## 相关文档

- 课程要求：`docs/大作业要求.md`
- 设计报告：`docs/2025设计报告.md`
- 后端 API：`backend/API使用手册.md`

---

最后更新：2025-12-24
