"""
通用响应模型
"""
from typing import Optional, Any, Generic, TypeVar
from pydantic import BaseModel, Field

T = TypeVar('T')


class ResponseModel(BaseModel, Generic[T]):
    """统一响应模型"""
    
    success: bool = Field(description="请求是否成功")
    code: int = Field(description="状态码")
    message: str = Field(description="响应消息")
    data: Optional[T] = Field(default=None, description="响应数据")
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "code": 200,
                "message": "操作成功",
                "data": None
            }
        }


class PaginationModel(BaseModel):
    """分页模型"""
    
    total: int = Field(description="总记录数")
    page: int = Field(description="当前页码")
    page_size: int = Field(description="每页大小")
    total_pages: int = Field(description="总页数")
    

class PaginatedResponseModel(BaseModel, Generic[T]):
    """分页响应模型"""
    
    success: bool = True
    code: int = 200
    message: str = "查询成功"
    data: list[T] = Field(default_factory=list)
    pagination: PaginationModel
