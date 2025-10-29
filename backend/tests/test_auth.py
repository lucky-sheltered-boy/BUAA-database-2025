"""
认证接口测试
"""


def test_login_success(test_client):
    """测试登录成功"""
    response = test_client.post(
        "/api/auth/login",
        json={
            "username": "2021001",
            "password": "123456"
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "access_token" in data["data"]
    assert "user_info" in data["data"]


def test_login_wrong_password(test_client):
    """测试密码错误"""
    response = test_client.post(
        "/api/auth/login",
        json={
            "username": "2021001",
            "password": "wrong_password"
        }
    )
    
    assert response.status_code == 401


def test_login_user_not_found(test_client):
    """测试用户不存在"""
    response = test_client.post(
        "/api/auth/login",
        json={
            "username": "9999999",
            "password": "123456"
        }
    )
    
    assert response.status_code == 401
