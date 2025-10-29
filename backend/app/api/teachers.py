"""
教师 API 路由
"""
from fastapi import APIRouter, Path, Query
from typing import List

from app.models.common import ResponseModel
from app.database import db_pool
from app.dal.stored_procedures import sp
from app.utils.logger import logger

router = APIRouter()


@router.get("/{teacher_id}/schedule", response_model=ResponseModel[List[dict]])
async def get_teacher_schedule(
    teacher_id: int = Path(..., description="教师ID", gt=0),
    semester_id: int = Query(..., description="学期ID", gt=0)
):
    """
    查询教师课表
    
    调用存储过程 sp_get_teacher_schedule
    """
    try:
        with db_pool.get_cursor() as cursor:
            # 调用存储过程
            schedule = sp.sp_get_teacher_schedule(cursor, teacher_id, semester_id)
            
            # 转换为响应格式
            schedule_list = [
                {
                    "course_id": s['课程ID'],
                    "course_name": s['课程名称'],
                    "weekday": s['星期'],
                    "start_time": str(s['开始时间']),
                    "end_time": str(s['结束时间']),
                    "building": s['教学楼'],
                    "room": s['房间号'],
                    "week_range": f"{s['起始周']}-{s['结束周']}周",
                    "week_type": s['单双周'],
                    "enrolled_students": s['已选人数'],
                    "total_quota": s['总名额']
                }
                for s in schedule
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(schedule_list)} 条授课安排",
                data=schedule_list
            )
            
    except Exception as e:
        logger.error(f"查询教师课表失败: {str(e)}")
        raise


@router.get("/{teacher_id}/students", response_model=ResponseModel[List[dict]])
async def get_enrolled_students(
    teacher_id: int = Path(..., description="教师ID", gt=0),
    instance_id: int = Query(..., description="开课实例ID", gt=0)
):
    """
    查询某开课实例的选课学生名单
    """
    try:
        with db_pool.get_cursor() as cursor:
            # 先验证教师是否教授该课程
            verify_sql = """
                SELECT COUNT(*) as count 
                FROM `授课关系表` 
                WHERE `教师ID` = %s AND `开课实例ID` = %s
            """
            cursor.execute(verify_sql, (teacher_id, instance_id))
            result = cursor.fetchone()
            
            if result['count'] == 0:
                return ResponseModel(
                    success=False,
                    code=403,
                    message="您没有权限查看该课程的学生名单",
                    data=[]
                )
            
            # 查询选课学生
            sql = """
                SELECT 
                    u.`用户ID`,
                    u.`学号_工号` AS `学号`,
                    u.`姓名`,
                    d.`院系名称`,
                    sc.`选课时间`,
                    CASE 
                        WHEN u.`院系ID` = c.`院系ID` THEN '本院系'
                        ELSE '跨院系'
                    END AS `选课类型`
                FROM `选课记录表` sc
                JOIN `用户信息表` u ON sc.`学生ID` = u.`用户ID`
                JOIN `院系信息表` d ON u.`院系ID` = d.`院系ID`
                JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
                JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
                WHERE sc.`开课实例ID` = %s
                ORDER BY u.`学号_工号`
            """
            cursor.execute(sql, (instance_id,))
            students = cursor.fetchall()
            
            # 转换时间格式
            student_list = [
                {
                    "user_id": s['用户ID'],
                    "student_number": s['学号'],
                    "name": s['姓名'],
                    "department": s['院系名称'],
                    "enroll_time": s['选课时间'].strftime('%Y-%m-%d %H:%M:%S'),
                    "enroll_type": s['选课类型']
                }
                for s in students
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(student_list)} 名学生",
                data=student_list
            )
            
    except Exception as e:
        logger.error(f"查询学生名单失败: {str(e)}")
        raise
