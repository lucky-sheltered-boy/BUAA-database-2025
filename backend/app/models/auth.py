"""
认证相关模型
"""
from pydantic import BaseModel, Field
from typing import Optional


class LoginRequest(BaseModel):
    """登录请求"""
    
    username: str = Field(..., description="用户名（学号或工号）", min_length=1, max_length=20)
    password: str = Field(..., description="密码", min_length=6, max_length=50)
    
    class Config:
        json_schema_extra = {
            "example": {
                "username": "2021001",
                "password": "123456"
            }
        }


class TokenResponse(BaseModel):
    """Token 响应"""
    
    access_token: str = Field(..., description="访问令牌")
    refresh_token: str = Field(..., description="刷新令牌")
    token_type: str = Field(default="Bearer", description="令牌类型")
    expires_in: int = Field(..., description="过期时间（秒）")
    user_info: dict = Field(..., description="用户信息")
    
    class Config:
        json_schema_extra = {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "Bearer",
                "expires_in": 1800,
                "user_info": {
                    "user_id": 1,
                    "username": "2021001",
                    "name": "张三",
                    "role": "学生",
                    "department_id": 1
                }
            }
        }


class RefreshTokenRequest(BaseModel):
    """刷新令牌请求"""
    
    refresh_token: str = Field(..., description="刷新令牌")


class CurrentUser(BaseModel):
    """当前用户信息（从 Token 解析）"""
    
    user_id: int
    username: str
    name: str
    role: str  # 学生/教师/教务
    department_id: int


class ChangePasswordRequest(BaseModel):
    """修改密码请求"""
    
    old_password: str = Field(..., description="原密码", min_length=6, max_length=50)
    new_password: str = Field(..., description="新密码", min_length=6, max_length=50)
    
    class Config:
        json_schema_extra = {
            "example": {
                "old_password": "123456",
                "new_password": "newpass123"
            }
        }
