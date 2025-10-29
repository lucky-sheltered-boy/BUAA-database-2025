"""
测试登录接口
"""
import requests
import json

url = "http://localhost:8000/api/auth/login"

data = {
    "username": "2021001",
    "password": "123456"
}

print("🔍 测试登录接口...")
print(f"URL: {url}")
print(f"请求数据: {json.dumps(data, ensure_ascii=False, indent=2)}")
print("\n" + "="*50 + "\n")

try:
    response = requests.post(url, json=data)
    
    print(f"状态码: {response.status_code}")
    print(f"响应:\n{json.dumps(response.json(), ensure_ascii=False, indent=2)}")
    
    if response.status_code == 200:
        result = response.json()
        if result.get("success"):
            print("\n✅ 登录成功！")
            token = result["data"]["access_token"]
            print(f"\n📋 Access Token (前50字符):")
            print(f"{token[:50]}...")
            print(f"\n👤 用户信息:")
            user_info = result["data"]["user_info"]
            for key, value in user_info.items():
                print(f"  {key}: {value}")
        else:
            print("\n❌ 登录失败")
    else:
        print("\n❌ 请求失败")
        
except requests.exceptions.ConnectionError:
    print("❌ 无法连接到服务器，请确保服务已启动")
    print("   启动命令: python -m uvicorn app.main:app --reload --port 8000")
except Exception as e:
    print(f"❌ 错误: {e}")
