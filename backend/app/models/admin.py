"""
管理员相关模型
"""
from pydantic import BaseModel, Field
from typing import Optional, List


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


# 开课管理相关模型

class TimeSlotRequest(BaseModel):
    """时间段请求"""
    
    weekday: int = Field(..., description="星期（1-7）", ge=1, le=7)
    time_slot: int = Field(..., description="时间段（1-5）", ge=1, le=5)
    start_week: int = Field(..., description="起始周", ge=1, le=20)
    end_week: int = Field(..., description="结束周", ge=1, le=20)
    week_type: str = Field(..., description="单双周", pattern="^(全部|单周|双周)$")
    teacher_id: int = Field(..., description="授课教师ID", gt=0)


class CreateInstanceRequest(BaseModel):
    """创建开课实例请求"""
    
    course_id: str = Field(..., description="课程ID", min_length=1, max_length=20)
    semester_id: int = Field(..., description="学期ID", gt=0)
    classroom_id: int = Field(..., description="教室ID", gt=0)
    quota_inner: int = Field(..., description="对内名额", ge=0)
    quota_outer: int = Field(..., description="对外名额", ge=0)
    teachers: List[int] = Field(..., description="授课教师ID列表", min_length=1)
    time_slots: List[TimeSlotRequest] = Field(..., description="上课时间列表", min_length=1)
    
    class Config:
        json_schema_extra = {
            "example": {
                "course_id": "CS201",
                "semester_id": 1,
                "classroom_id": 5,
                "quota_inner": 50,
                "quota_outer": 20,
                "teachers": [16, 17],
                "time_slots": [
                    {
                        "weekday": 1,
                        "time_slot": 1,
                        "start_week": 1,
                        "end_week": 16,
                        "week_type": "全部",
                        "teacher_id": 16
                    }
                ]
            }
        }


class ClassroomResponse(BaseModel):
    """教室响应"""
    
    classroom_id: int
    building: str
    room_number: str
    capacity: int
    
    class Config:
        json_schema_extra = {
            "example": {
                "classroom_id": 1,
                "building": "主楼",
                "room_number": "301",
                "capacity": 80
            }
        }


class SemesterResponse(BaseModel):
    """学期响应"""
    
    semester_id: int
    semester_name: str
    
    class Config:
        json_schema_extra = {
            "example": {
                "semester_id": 1,
                "semester_name": "2024-2025 秋季"
            }
        }


class CourseInstanceResponse(BaseModel):
    """开课实例响应"""
    
    instance_id: int
    course_id: str
    course_name: str
    semester_name: str
    building: str
    room_number: str
    quota_inner: int
    quota_outer: int
    enrolled_inner: int
    enrolled_outer: int
    teachers: str  # 教师名单，逗号分隔
    
    class Config:
        json_schema_extra = {
            "example": {
                "instance_id": 1,
                "course_id": "CS201",
                "course_name": "数据结构",
                "semester_name": "2024-2025 秋季",
                "building": "主楼",
                "room_number": "301",
                "quota_inner": 50,
                "quota_outer": 20,
                "enrolled_inner": 30,
                "enrolled_outer": 10,
                "teachers": "张三, 李四"
            }
        }
