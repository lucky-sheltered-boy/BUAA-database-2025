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
        self._init_attempted = False
        # 不在初始化时立即连接，而是延迟到第一次使用
        # self._init_pool()
    
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
                ping=7,  # 检查连接有效性：7=always (最强保活机制)
                host=settings.DB_HOST,
                port=settings.DB_PORT,
                user=settings.DB_USER,
                password=settings.DB_PASSWORD,
                database=settings.DB_NAME,
                charset=settings.DB_CHARSET,
                ssl=ssl_config,
                cursorclass=pymysql.cursors.DictCursor,  # 返回字典格式
                autocommit=False,  # 手动控制事务
                # 新增超时和重连配置
                connect_timeout=settings.DB_CONNECT_TIMEOUT,  # 连接超时
                read_timeout=settings.DB_READ_TIMEOUT,        # 读取超时
                write_timeout=settings.DB_WRITE_TIMEOUT,      # 写入超时
            )
            
            logger.info(f"数据库连接池初始化成功: {settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}")
            
        except Exception as e:
            logger.error(f"数据库连接池初始化失败: {str(e)}")
            raise
    
    def _ensure_pool(self):
        """确保连接池已初始化"""
        if self._pool is None and not self._init_attempted:
            self._init_attempted = True
            self._init_pool()
    
    def get_connection(self):
        """获取数据库连接（带重试机制）"""
        self._ensure_pool()
        if not self._pool:
            self._init_pool()
        
        # 添加重试机制
        max_retries = 3
        retry_count = 0
        last_error = None
        
        while retry_count < max_retries:
            try:
                conn = self._pool.connection()
                # 测试连接是否有效
                conn.ping(reconnect=True)
                return conn
            except Exception as e:
                retry_count += 1
                last_error = e
                logger.warning(f"获取数据库连接失败 (尝试 {retry_count}/{max_retries}): {str(e)}")
                
                # 如果不是最后一次重试，重置连接池
                if retry_count < max_retries:
                    try:
                        self._pool = None
                        self._init_attempted = False
                        self._ensure_pool()
                    except Exception as init_error:
                        logger.error(f"重新初始化连接池失败: {str(init_error)}")
        
        # 所有重试都失败
        logger.error(f"获取数据库连接失败，已重试 {max_retries} 次")
        raise last_error
    
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
