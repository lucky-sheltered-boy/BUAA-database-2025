"""
数据库连接池管理
使用 PyMySQL + DBUtils 连接华为云 TaurusDB
"""
import pymysql
from dbutils.pooled_db import PooledDB
from contextlib import contextmanager
from typing import Generator
from app.config import settings
from app.utils.logger import logger


class DatabasePool:
    """数据库连接池"""
    
    def __init__(self):
        self._pool = None
        self._init_pool()
    
    def _init_pool(self):
        """初始化连接池"""
        try:
            # SSL/TLS 配置
            ssl_config = None
            if settings.DB_USE_SSL and settings.DB_SSL_CA_PATH:
                ssl_config = {
                    'ca': settings.DB_SSL_CA_PATH,
                    'check_hostname': False,
                    'verify_mode': 2  # CERT_REQUIRED
                }
            
            # 创建连接池
            self._pool = PooledDB(
                creator=pymysql,
                maxconnections=settings.DB_POOL_MAX_SIZE,
                mincached=settings.DB_POOL_MIN_SIZE,
                maxcached=settings.DB_POOL_MAX_SIZE,
                maxshared=0,  # 不共享连接
                blocking=True,  # 连接不够时阻塞等待
                maxusage=None,  # 连接最大使用次数，None 表示无限制
                setsession=[],
                ping=1,  # 检查连接有效性：0=None, 1=default, 2=when checked out, 4=when checked in, 7=always
                host=settings.DB_HOST,
                port=settings.DB_PORT,
                user=settings.DB_USER,
                password=settings.DB_PASSWORD,
                database=settings.DB_NAME,
                charset=settings.DB_CHARSET,
                ssl=ssl_config,
                cursorclass=pymysql.cursors.DictCursor,  # 返回字典格式
                autocommit=False  # 手动控制事务
            )
            
            logger.info(f"数据库连接池初始化成功: {settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}")
            
        except Exception as e:
            logger.error(f"数据库连接池初始化失败: {str(e)}")
            raise
    
    def get_connection(self):
        """获取数据库连接"""
        if not self._pool:
            self._init_pool()
        return self._pool.connection()
    
    @contextmanager
    def get_cursor(self, commit: bool = False) -> Generator:
        """
        获取游标的上下文管理器
        
        Args:
            commit: 是否自动提交事务
        
        Usage:
            with db_pool.get_cursor(commit=True) as cursor:
                cursor.execute("SELECT * FROM users")
                results = cursor.fetchall()
        """
        connection = self.get_connection()
        cursor = connection.cursor()
        
        try:
            yield cursor
            if commit:
                connection.commit()
        except Exception as e:
            connection.rollback()
            logger.error(f"数据库操作失败: {str(e)}")
            raise
        finally:
            cursor.close()
            connection.close()
    
    def close(self):
        """关闭连接池"""
        if self._pool:
            self._pool.close()
            logger.info("数据库连接池已关闭")


# 全局连接池实例
db_pool = DatabasePool()


# 依赖注入函数
def get_db_cursor(commit: bool = False):
    """
    FastAPI 依赖注入：获取数据库游标
    
    Usage:
        @app.get("/users")
        def get_users(cursor = Depends(get_db_cursor)):
            cursor.execute("SELECT * FROM users")
            return cursor.fetchall()
    """
    return db_pool.get_cursor(commit=commit)
