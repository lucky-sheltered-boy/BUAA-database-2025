"""
学生 API 路由
"""
from fastapi import APIRouter, Path, Query
from typing import List

from app.models.common import ResponseModel
from app.models.enrollment import (
    EnrollRequest, DropRequest, AvailableCourse, StudentSchedule
)
from app.database import db_pool
from app.dal.stored_procedures import sp
from app.utils.logger import logger
from app.utils.exceptions import BusinessError

router = APIRouter()


@router.get("/{student_id}/available-courses", 
           response_model=ResponseModel[List[AvailableCourse]])
async def get_available_courses(
    student_id: int = Path(..., description="学生ID", gt=0)
):
    """
    查询可选课程列表
    
    调用存储过程 sp_get_available_courses
    """
    try:
        # 增加重试机制
        max_retries = 3
        last_error = None
        
        for attempt in range(max_retries):
            try:
                with db_pool.get_cursor() as cursor:
                    # 调用存储过程
                    courses = sp.sp_get_available_courses(cursor, student_id)
                    
                    # 获取附加信息（教师和时间段）
                    teachers_map = {}
                    slots_map = {}
                    
                    if courses:
                        instance_ids = [str(c['开课实例ID']) for c in courses]
                        ids_str = ",".join(instance_ids)
                        
                        # 获取教师信息
                        cursor.execute(f"""
                            SELECT t.`开课实例ID`, u.`姓名`
                            FROM `授课关系表` t
                            JOIN `用户信息表` u ON t.`教师ID` = u.`用户ID`
                            WHERE t.`开课实例ID` IN ({ids_str})
                        """)
                        for row in cursor.fetchall():
                            iid = row['开课实例ID']
                            if iid not in teachers_map:
                                teachers_map[iid] = []
                            teachers_map[iid].append({"name": row['姓名']})
                            
                        # 获取时间段信息
                        cursor.execute(f"""
                            SELECT t.`开课实例ID`, ts.`星期`, ts.`开始时间`, ts.`结束时间`
                            FROM `上课时间表` t
                            JOIN `时间段信息表` ts ON t.`时间段ID` = ts.`时间段ID`
                            WHERE t.`开课实例ID` IN ({ids_str})
                        """)
                        for row in cursor.fetchall():
                            iid = row['开课实例ID']
                            if iid not in slots_map:
                                slots_map[iid] = []
                            
                            slots_map[iid].append({
                                "day_of_week": row['星期'],
                                "start_time": str(row['开始时间']),
                                "end_time": str(row['结束时间'])
                            })

                    # 转换为响应模型
                    course_list = [
                        AvailableCourse(
                            instance_id=c['开课实例ID'],
                            course_id=c['课程ID'],
                            course_name=c['课程名称'],
                            credit=float(c['学分']),
                            department=c['开课院系'],
                            building=c['教学楼'],
                            room=c['房间号'],
                            remaining_quota=c['剩余名额'],
                            # 兼容旧版存储过程，如果缺少总名额字段则默认为0
                            total_quota=c.get('总名额', 0),
                            enroll_type=c['选课类型'],
                            teachers=teachers_map.get(c['开课实例ID'], []),
                            time_slots=slots_map.get(c['开课实例ID'], [])
                        )
                        for c in courses
                    ]
                    
                    return ResponseModel(
                        success=True,
                        code=200,
                        message=f"查询到 {len(course_list)} 门可选课程",
                        data=course_list
                    )
            except Exception as e:
                last_error = e
                error_str = str(e)
                # 检查是否是连接错误 (2006: Gone away, 2013: Lost connection)
                if '2006' in error_str or '2013' in error_str or 'Lost connection' in error_str:
                    if attempt < max_retries - 1:
                        logger.warning(f"数据库连接中断，重试查询可选课程 {attempt + 1}/{max_retries}")
                        continue
                raise last_error
            
    except Exception as e:
        logger.error(f"查询可选课程失败: {str(e)}")
        raise


@router.post("/{student_id}/enroll", response_model=ResponseModel[None])
async def enroll_course(
    request: EnrollRequest,
    student_id: int = Path(..., description="学生ID", gt=0)
):
    """
    学生选课
    
    调用存储过程 sp_student_enroll
    
    触发器会自动检查：
    - 名额限制（对内/对外）
    - 时间冲突
    - 选课时间窗口
    - 重复选课
    """
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            # 调用存储过程（带重试机制处理并发死锁）
            max_retries = 3
            for attempt in range(max_retries):
                try:
                    message = sp.sp_student_enroll(cursor, student_id, request.instance_id)
                    
                    logger.info(f"学生 {student_id} 选课成功: 开课实例 {request.instance_id}")
                    
                    return ResponseModel(
                        success=True,
                        code=200,
                        message=message,
                        data=None
                    )
                    
                except Exception as e:
                    error_str = str(e)
                    # 检查是否是死锁错误或连接错误
                    if '1213' in error_str or 'Deadlock' in error_str or \
                       '2006' in error_str or '2013' in error_str or 'Lost connection' in error_str:
                        if attempt < max_retries - 1:
                            logger.warning(f"数据库操作异常(死锁或连接中断)，重试 {attempt + 1}/{max_retries}")
                            continue
                    raise
            
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"选课失败: {str(e)}")
        raise


@router.post("/{student_id}/drop", response_model=ResponseModel[None])
async def drop_course(
    request: DropRequest,
    student_id: int = Path(..., description="学生ID", gt=0)
):
    """
    学生退课
    
    调用存储过程 sp_student_drop
    """
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            message = sp.sp_student_drop(cursor, student_id, request.instance_id)
            
            logger.info(f"学生 {student_id} 退课成功: 开课实例 {request.instance_id}")
            
            return ResponseModel(
                success=True,
                code=200,
                message=message,
                data=None
            )
            
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"退课失败: {str(e)}")
        raise


@router.get("/{student_id}/schedule", 
           response_model=ResponseModel[List[StudentSchedule]])
async def get_student_schedule(
    student_id: int = Path(..., description="学生ID", gt=0),
    semester_id: int = Query(..., description="学期ID", gt=0)
):
    """
    查询学生课表
    
    调用存储过程 sp_get_student_schedule
    """
    try:
        with db_pool.get_cursor() as cursor:
            # 调用存储过程
            schedule = sp.sp_get_student_schedule(cursor, student_id, semester_id)
            
            # 转换为响应模型
            schedule_list = [
                StudentSchedule(
                    instance_id=s['开课实例ID'],  # 添加开课实例ID
                    course_id=s['课程ID'],
                    course_name=s['课程名称'],
                    credit=float(s['学分']),
                    weekday=s['星期'],
                    start_time=str(s['开始时间']),
                    end_time=str(s['结束时间']),
                    building=s['教学楼'],
                    room=s['房间号'],
                    teacher_name=s['教师姓名'],
                    week_range=f"{s['起始周']}-{s['结束周']}周",
                    week_type=s['单双周']
                )
                for s in schedule
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(schedule_list)} 条课程安排",
                data=schedule_list
            )
            
    except Exception as e:
        logger.error(f"查询学生课表失败: {str(e)}")
        raise
