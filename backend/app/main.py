"""
FastAPI 主应用
"""
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import HTTPBearer
from contextlib import asynccontextmanager

from app.config import settings
from app.database import db_pool
from app.utils.logger import logger
from app.utils.exceptions import BaseAPIException
from app.models.common import ResponseModel

# 导入路由
from app.api import auth, students, teachers, statistics, admin

# 定义安全方案（这样 Swagger UI 才会显示 Authorize 按钮）
security = HTTPBearer()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时
    logger.info(f"🚀 {settings.APP_NAME} v{settings.APP_VERSION} 启动中...")
    logger.info(f"环境: {settings.ENVIRONMENT}")
    logger.info(f"数据库: {settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}")
    
    yield
    
    # 关闭时
    logger.info("⏹️  应用关闭中...")
    db_pool.close()
    logger.info("✅ 应用已关闭")


# 创建 FastAPI 应用
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="基于 FastAPI + 华为云 TaurusDB 的排课选课管理系统",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
    # 添加安全方案定义，使 Swagger UI 显示 Authorize 按钮
    swagger_ui_init_oauth={
        "usePkceWithAuthorizationCodeGrant": True,
    },
    # 定义全局安全方案
    openapi_tags=[
        {"name": "认证", "description": "用户认证相关接口"},
        {"name": "学生", "description": "学生选课、查询课表等功能"},
        {"name": "教师", "description": "教师查看授课安排、学生名单等功能"},
        {"name": "统计", "description": "数据统计和报表功能"},
        {"name": "管理", "description": "管理员功能：用户、课程、院系管理"},
    ]
)


# 自定义 OpenAPI schema 以添加安全方案
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    from fastapi.openapi.utils import get_openapi
    
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    
    # 添加安全方案定义
    openapi_schema["components"]["securitySchemes"] = {
        "HTTPBearer": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
            "description": "在此处输入 JWT token（格式：Bearer <token>）"
        }
    }
    
    # 为需要认证的路由添加安全要求
    # 注意：登录和刷新token接口不需要认证
    for path, path_item in openapi_schema["paths"].items():
        # 跳过认证相关的接口
        if "/auth/login" in path or "/auth/refresh" in path or path == "/" or path == "/health":
            continue
        
        # 为其他接口添加安全要求
        for method in path_item:
            if method in ["get", "post", "put", "delete", "patch"]:
                path_item[method]["security"] = [{"HTTPBearer": []}]
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema


app.openapi = custom_openapi


# CORS 中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=["*"],
    allow_headers=["*"],
)


# 全局异常处理
@app.exception_handler(BaseAPIException)
async def api_exception_handler(request: Request, exc: BaseAPIException):
    """处理自定义 API 异常"""
    logger.warning(f"API 异常: {exc.code} - {exc.message}")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "code": exc.status_code,
            "message": exc.message,
            "data": exc.details
        }
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """处理未捕获的异常"""
    logger.error(f"未处理异常: {type(exc).__name__} - {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "code": 500,
            "message": "服务器内部错误" if not settings.DEBUG else str(exc),
            "data": None
        }
    )


# 根路由
@app.get("/", response_model=ResponseModel[dict])
async def root():
    """根路径"""
    return ResponseModel(
        success=True,
        code=200,
        message=f"欢迎使用 {settings.APP_NAME}",
        data={
            "version": settings.APP_VERSION,
            "docs": "/docs",
            "health": "/health"
        }
    )


# 健康检查
@app.get("/health", response_model=ResponseModel[dict])
async def health_check():
    """健康检查"""
    try:
        # 测试数据库连接
        with db_pool.get_cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        
        return ResponseModel(
            success=True,
            code=200,
            message="服务正常",
            data={
                "status": "healthy",
                "database": "connected",
                "environment": settings.ENVIRONMENT
            }
        )
    except Exception as e:
        logger.error(f"健康检查失败: {str(e)}")
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "success": False,
                "code": 503,
                "message": "服务不可用",
                "data": {
                    "status": "unhealthy",
                    "database": "disconnected",
                    "error": str(e) if settings.DEBUG else None
                }
            }
        )


# 注册路由
app.include_router(auth.router, prefix="/api/auth", tags=["认证"])
app.include_router(students.router, prefix="/api/students", tags=["学生"])
app.include_router(teachers.router, prefix="/api/teachers", tags=["教师"])
app.include_router(statistics.router, prefix="/api/statistics", tags=["统计"])
app.include_router(admin.router, prefix="/api/admin", tags=["管理"])

# TODO: 添加更多路由
# app.include_router(departments.router, prefix="/api/departments", tags=["院系管理"])
# app.include_router(classrooms.router, prefix="/api/classrooms", tags=["教室管理"])
# app.include_router(courses.router, prefix="/api/courses", tags=["课程管理"])
# app.include_router(semesters.router, prefix="/api/semesters", tags=["学期管理"])
# app.include_router(users.router, prefix="/api/users", tags=["用户管理"])
# app.include_router(instances.router, prefix="/api/instances", tags=["开课实例"])


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
