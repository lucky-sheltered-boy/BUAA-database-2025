"""
选课相关模型
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class EnrollRequest(BaseModel):
    """选课请求"""
    
    instance_id: int = Field(..., description="开课实例ID", gt=0)
    
    class Config:
        json_schema_extra = {
            "example": {
                "instance_id": 1
            }
        }


class DropRequest(BaseModel):
    """退课请求"""
    
    instance_id: int = Field(..., description="开课实例ID", gt=0)


class AvailableCourse(BaseModel):
    """可选课程"""
    
    instance_id: int
    course_id: str
    course_name: str
    credit: float
    department: str
    building: str
    room: str
    remaining_quota: int
    enroll_type: str  # 本院系/跨院系


class StudentSchedule(BaseModel):
    """学生课表"""
    
    instance_id: int  # 添加开课实例ID用于退课
    course_id: str
    course_name: str
    credit: float
    weekday: str
    start_time: str
    end_time: str
    building: str
    room: str
    teacher_name: Optional[str]
    week_range: str
    week_type: str  # 全部/单周/双周
