"""
检查数据库中的用户数据
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from app.database import db_pool
from app.utils.logger import logger

try:
    with db_pool.get_cursor() as cursor:
        # 查询用户信息
        cursor.execute("""
            SELECT 用户ID, 学号_工号, 姓名, 角色, 密码哈希 
            FROM 用户信息表 
            WHERE 学号_工号 = %s
        """, ('2021001',))
        
        user = cursor.fetchone()
        
        if user:
            logger.info(f"✅ 找到用户：")
            logger.info(f"   用户ID: {user['用户ID']}")
            logger.info(f"   学号_工号: {user['学号_工号']}")
            logger.info(f"   姓名: {user['姓名']}")
            logger.info(f"   角色: {user['角色']}")
            logger.info(f"   密码哈希: {user['密码哈希'][:50]}...")
            
            # 检查密码格式
            pwd_hash = user['密码哈希']
            if pwd_hash.startswith('hash_'):
                logger.info("   密码格式: MD5 (hash_ 前缀)")
                import hashlib
                test_pwd = "123456"
                expected = "hash_" + hashlib.md5(test_pwd.encode()).hexdigest()
                logger.info(f"   期望的哈希: {expected}")
                if pwd_hash == expected:
                    logger.success("   ✅ 密码匹配！")
                else:
                    logger.error("   ❌ 密码不匹配！")
            else:
                logger.info("   密码格式: 其他格式")
        else:
            logger.error("❌ 未找到用户 2021001")
            
            # 列出所有用户
            cursor.execute("SELECT 学号_工号, 姓名, 角色 FROM 用户信息表 LIMIT 10")
            all_users = cursor.fetchall()
            logger.info("\n数据库中的用户列表：")
            for u in all_users:
                logger.info(f"  - {u['学号_工号']} ({u['姓名']}, {u['角色']})")
                
except Exception as e:
    logger.error(f"❌ 错误: {e}")
    import traceback
    traceback.print_exc()
