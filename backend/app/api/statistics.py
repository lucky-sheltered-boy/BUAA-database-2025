"""
统计报表 API 路由
"""
from fastapi import APIRouter, Query
from typing import List

from app.models.common import ResponseModel
from app.database import db_pool
from app.dal.stored_procedures import sp
from app.utils.logger import logger

router = APIRouter()


@router.get("/enrollment", response_model=ResponseModel[List[dict]])
async def get_enrollment_statistics(
    semester_id: int = Query(..., description="学期ID", gt=0)
):
    """
    查询选课统计
    
    调用存储过程 sp_get_enrollment_statistics
    """
    try:
        with db_pool.get_cursor() as cursor:
            # 调用存储过程
            stats = sp.sp_get_enrollment_statistics(cursor, semester_id)
            
            # 转换为响应格式
            stats_list = [
                {
                    "course_id": s['课程ID'],
                    "course_name": s['课程名称'],
                    "department": s['院系名称'],
                    "quota_inner": s['对内名额'],
                    "quota_outer": s['对外名额'],
                    "enrolled_inner": s['已选对内人数'],
                    "enrolled_outer": s['已选对外人数'],
                    "total_enrolled": s['总选课人数'],
                    "total_quota": s['总名额'],
                    "enrollment_rate": s['选课率']
                }
                for s in stats
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(stats_list)} 门课程的统计数据",
                data=stats_list
            )
            
    except Exception as e:
        logger.error(f"查询选课统计失败: {str(e)}")
        raise


@router.get("/overview", response_model=ResponseModel[dict])
async def get_system_overview():
    """
    获取系统概览统计
    """
    try:
        with db_pool.get_cursor() as cursor:
            # 统计各类数据
            overview = {}
            
            # 院系数量
            cursor.execute("SELECT COUNT(*) as count FROM `院系信息表`")
            overview['departments'] = cursor.fetchone()['count']
            
            # 用户统计
            cursor.execute("""
                SELECT `角色`, COUNT(*) as count 
                FROM `用户信息表` 
                GROUP BY `角色`
            """)
            users = cursor.fetchall()
            overview['users'] = {u['角色']: u['count'] for u in users}
            
            # 课程数量
            cursor.execute("SELECT COUNT(*) as count FROM `课程信息表`")
            overview['courses'] = cursor.fetchone()['count']
            
            # 教室数量
            cursor.execute("SELECT COUNT(*) as count FROM `教室信息表`")
            overview['classrooms'] = cursor.fetchone()['count']
            
            # 当前学期开课数量
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM `开课实例表` oi
                JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`
                WHERE s.`是否当前学期` = TRUE
            """)
            overview['current_instances'] = cursor.fetchone()['count']
            
            # 当前学期选课总数
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM `选课记录表` sc
                JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
                JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`
                WHERE s.`是否当前学期` = TRUE
            """)
            overview['current_enrollments'] = cursor.fetchone()['count']
            
            return ResponseModel(
                success=True,
                code=200,
                message="系统概览统计",
                data=overview
            )
            
    except Exception as e:
        logger.error(f"查询系统概览失败: {str(e)}")
        raise
