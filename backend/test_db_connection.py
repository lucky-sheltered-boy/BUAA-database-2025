"""
数据库连接诊断工具 - 增强版
用于快速诊断和解决数据库连接问题
"""
import pymysql
import time
from datetime import datetime


# 数据库配置
DB_CONFIG = {
    'host': '124.70.86.207',
    'port': 3306,
    'user': 'u23371524',
    'password': 'Aa270108',
    'database': 'h_db23371524',
    'charset': 'utf8mb4',
    'connect_timeout': 30,  # 增加超时时间
    'read_timeout': 30,
    'write_timeout': 30,
}


def test_basic_connection():
    """测试1: 基础连接"""
    print("\n" + "=" * 60)
    print("[测试 1] 基础连接测试")
    print("=" * 60)
    print(f"主机: {DB_CONFIG['host']}")
    print(f"端口: {DB_CONFIG['port']}")
    print(f"用户: {DB_CONFIG['user']}")
    print(f"数据库: {DB_CONFIG['database']}")
    
    try:
        print(f"\n[{datetime.now().strftime('%H:%M:%S')}] 正在连接...")
        start_time = time.time()
        
        conn = pymysql.connect(**DB_CONFIG)
        elapsed = time.time() - start_time
        
        print(f"✅ 连接成功! (耗时: {elapsed:.2f}秒)")
        
        cursor = conn.cursor()
        cursor.execute("SELECT VERSION(), DATABASE(), NOW()")
        result = cursor.fetchone()
        
        print(f"   MySQL版本: {result[0]}")
        print(f"   当前数据库: {result[1]}")
        print(f"   服务器时间: {result[2]}")
        
        cursor.close()
        conn.close()
        return True
        
    except pymysql.err.OperationalError as e:
        error_code, error_msg = e.args
        print(f"❌ 连接失败 (错误码: {error_code})")
        print(f"   {error_msg}")
        
        if error_code == 2013:
            print("\n💡 这是您遇到的错误!")
            print("   原因: 连接在查询期间断开")
            print("   解决方案:")
            print("   1. 检查网络连接是否稳定")
            print("   2. 数据库服务器可能重启或维护中")
            print("   3. 稍后重试")
        
        return False
        
    except Exception as e:
        print(f"❌ 连接失败: {str(e)}")
        return False


def test_connection_stability():
    """测试2: 连接稳定性（10次连续查询）"""
    print("\n" + "=" * 60)
    print("[测试 2] 连接稳定性测试（10次查询，间隔1秒）")
    print("=" * 60)
    
    try:
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        success_count = 0
        for i in range(1, 11):
            try:
                # 使用 ping 检查连接
                conn.ping(reconnect=True)
                
                cursor.execute("SELECT %s, NOW()", (i,))
                result = cursor.fetchone()
                
                print(f"  查询 {i:2d}/10: ✅ {result[1]}")
                success_count += 1
                
                if i < 10:
                    time.sleep(1)
                    
            except Exception as e:
                print(f"  查询 {i:2d}/10: ❌ {str(e)}")
        
        cursor.close()
        conn.close()
        
        print(f"\n成功率: {success_count}/10 ({success_count*10}%)")
        return success_count == 10
        
    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
        return False


def test_table_access():
    """测试3: 数据表访问"""
    print("\n" + "=" * 60)
    print("[测试 3] 数据表访问测试")
    print("=" * 60)
    
    try:
        conn = pymysql.connect(**{**DB_CONFIG, 'cursorclass': pymysql.cursors.DictCursor})
        cursor = conn.cursor()
        
        tables = [
            ('departments', '院系表'),
            ('users', '用户表'),
            ('courses', '课程表'),
            ('semesters', '学期表'),
            ('enrollments', '选课记录表'),
        ]
        
        for table_name, table_desc in tables:
            try:
                cursor.execute(f"SELECT COUNT(*) as count FROM {table_name}")
                result = cursor.fetchone()
                count = result['count']
                print(f"  {table_desc:12s} ({table_name:15s}): ✅ {count:3d} 条记录")
            except Exception as e:
                print(f"  {table_desc:12s} ({table_name:15s}): ❌ {str(e)}")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
        return False


def main():
    """主测试函数"""
    print("\n" + "🔍 " * 20)
    print("数据库连接诊断工具 - 增强版")
    print("🔍 " * 20)
    
    results = []
    
    # 运行所有测试
    results.append(("基础连接", test_basic_connection()))
    
    if results[0][1]:  # 如果基础连接成功，继续其他测试
        results.append(("连接稳定性", test_connection_stability()))
        results.append(("表访问", test_table_access()))
    else:
        print("\n⚠️  基础连接失败，跳过后续测试")
    
    # 汇总结果
    print("\n" + "=" * 60)
    print("测试结果汇总")
    print("=" * 60)
    
    for test_name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {test_name:15s}: {status}")
    
    all_passed = all(result for _, result in results)
    
    print("\n" + "=" * 60)
    if all_passed:
        print("🎉 所有测试通过! 数据库连接正常。")
        print("\n✨ 已优化的配置:")
        print("  • 连接超时: 30秒")
        print("  • 连接保活: ping=7 (always)")
        print("  • 自动重连: 最多3次重试")
        print("\n📝 下一步:")
        print("  重启后端服务即可应用新配置:")
        print("  > python -m uvicorn app.main:app --reload --port 8000")
    else:
        print("⚠️  部分测试失败")
        print("\n🔧 故障排除建议:")
        print("  1. 检查网络连接: ping 124.70.86.207")
        print("  2. 确认数据库服务器状态（华为云控制台）")
        print("  3. 检查防火墙/安全组设置")
        print("  4. 稍后重试（服务器可能正在维护）")
    
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
