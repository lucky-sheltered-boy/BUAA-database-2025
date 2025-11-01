"""
管理员相关模型
"""
from pydantic import BaseModel, Field
from typing import Optional


class AddUserRequest(BaseModel):
    """添加用户请求（学生/教师）"""
    
    student_id: str = Field(..., description="学号/工号", min_length=1, max_length=20)
    name: str = Field(..., description="姓名", min_length=1, max_length=50)
    password: str = Field(..., description="密码", min_length=6, max_length=255)
    role: str = Field(..., description="角色", pattern="^(学生|教师|教务)$")
    department_id: int = Field(..., description="院系ID", gt=0)
    
    class Config:
        json_schema_extra = {
            "example": {
                "student_id": "2024001",
                "name": "张三",
                "password": "123456",
                "role": "学生",
                "department_id": 1
            }
        }


class AddCourseRequest(BaseModel):
    """添加课程请求"""
    
    course_id: str = Field(..., description="课程ID", min_length=1, max_length=20)
    course_name: str = Field(..., description="课程名称", min_length=1, max_length=100)
    credit: float = Field(..., description="学分", gt=0, le=10)
    department_id: int = Field(..., description="院系ID", gt=0)
    
    class Config:
        json_schema_extra = {
            "example": {
                "course_id": "CS104",
                "course_name": "人工智能导论",
                "credit": 3.0,
                "department_id": 1
            }
        }


class AddDepartmentRequest(BaseModel):
    """添加院系请求"""
    
    department_name: str = Field(..., description="院系名称", min_length=1, max_length=100)
    
    class Config:
        json_schema_extra = {
            "example": {
                "department_name": "人工智能学院"
            }
        }


class UserResponse(BaseModel):
    """用户响应"""
    
    user_id: int
    student_id: str
    name: str
    role: str
    department_name: str


class CourseResponse(BaseModel):
    """课程响应"""
    
    course_id: str
    course_name: str
    credit: float
    department_name: str


class DepartmentResponse(BaseModel):
    """院系响应"""
    
    department_id: int
    department_name: str
