"""
配置管理模块
从环境变量读取配置
"""
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """应用配置"""
    
    # 应用配置
    APP_NAME: str = "高校智能排课选课管理系统"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"
    
    # 服务器配置
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # 数据库配置 (TaurusDB)
    DB_HOST: str
    DB_PORT: int = 3306
    DB_USER: str
    DB_PASSWORD: str
    DB_NAME: str
    DB_CHARSET: str = "utf8mb4"
    
    # 连接池配置
    DB_POOL_MIN_SIZE: int = 5
    DB_POOL_MAX_SIZE: int = 20
    DB_POOL_MAX_IDLE: int = 300  # 秒
    
    # 连接超时配置（秒）
    DB_CONNECT_TIMEOUT: int = 30  # 连接超时
    DB_READ_TIMEOUT: int = 30     # 读取超时
    DB_WRITE_TIMEOUT: int = 30    # 写入超时
    
    # TLS/SSL 配置
    DB_USE_SSL: bool = False
    DB_SSL_CA_PATH: str = ""
    
    # JWT 配置
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # CORS 配置
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:5173"]
    CORS_ALLOW_CREDENTIALS: bool = True
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "logs/app.log"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# 全局配置实例
settings = Settings()
