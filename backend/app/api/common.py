"""
通用 API 路由
"""
from fastapi import APIRouter
from typing import List

from app.models.common import ResponseModel
from app.models.admin import DepartmentResponse
from app.database import db_pool
from app.utils.logger import logger

router = APIRouter()

@router.get("/departments", response_model=ResponseModel[List[DepartmentResponse]])
async def get_departments():
    """
    获取所有院系列表
    """
    try:
        with db_pool.get_cursor() as cursor:
            sql = "SELECT `院系ID`, `院系名称` FROM `院系信息表` ORDER BY `院系ID`"
            cursor.execute(sql)
            results = cursor.fetchall()
            
            departments = [
                DepartmentResponse(
                    department_id=r['院系ID'],
                    department_name=r['院系名称']
                )
                for r in results
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message="获取院系列表成功",
                data=departments
            )
    except Exception as e:
        logger.error(f"获取院系列表失败: {str(e)}")
        raise
