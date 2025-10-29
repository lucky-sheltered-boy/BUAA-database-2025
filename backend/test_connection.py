"""
测试数据库连接
使用前请先在 .env 文件中配置 TaurusDB 连接信息
"""
import sys
from pathlib import Path

# 添加项目根目录到 Python 路径
sys.path.insert(0, str(Path(__file__).parent))

try:
    from app.database import db_pool
    from app.utils.logger import logger
    
    logger.info("🔍 正在测试 TaurusDB 连接...")
    
    # 测试连接
    with db_pool.get_cursor() as cursor:
        cursor.execute("SELECT VERSION()")
        version = cursor.fetchone()
        logger.success(f"✅ 数据库连接成功！")
        logger.info(f"📊 MySQL 版本: {version['VERSION()']}")
        
        # 测试数据库
        cursor.execute("SELECT DATABASE()")
        db = cursor.fetchone()
        logger.info(f"🗄️  当前数据库: {db['DATABASE()']}")
        
        # 测试表是否存在
        cursor.execute("""
            SELECT COUNT(*) as count 
            FROM information_schema.tables 
            WHERE table_schema = DATABASE()
            AND table_name = '用户信息表'
        """)
        result = cursor.fetchone()
        if result['count'] > 0:
            logger.success("✅ 数据表已存在")
            
            # 统计用户数量
            cursor.execute("SELECT COUNT(*) as count FROM 用户信息表")
            user_count = cursor.fetchone()
            logger.info(f"👥 用户总数: {user_count['count']}")
        else:
            logger.warning("⚠️  数据表不存在，请先执行数据库初始化脚本")
    
    logger.success("🎉 所有测试通过！可以启动后端服务了")
    print("\n" + "="*50)
    print("下一步：启动服务")
    print("命令: python -m uvicorn app.main:app --reload --port 8000")
    print("API文档: http://localhost:8000/docs")
    print("="*50)
    
except Exception as e:
    logger.error(f"❌ 连接失败: {e}")
    print("\n" + "="*50)
    print("请检查 .env 文件中的数据库配置：")
    print("- DB_HOST: TaurusDB 连接地址")
    print("- DB_PORT: 端口（默认 3306）")
    print("- DB_USER: 数据库用户名")
    print("- DB_PASSWORD: 数据库密码")
    print("- DB_NAME: 数据库名称")
    print("="*50)
    sys.exit(1)
