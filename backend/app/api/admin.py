"""
管理员 API 路由
"""
from fastapi import APIRouter, Query
from typing import List

from app.models.common import ResponseModel
from app.models.admin import (
    AddUserRequest, AddCourseRequest, AddDepartmentRequest,
    UserResponse, CourseResponse, DepartmentResponse,
    CreateInstanceRequest, ClassroomResponse, SemesterResponse,
    CourseInstanceResponse
)
from app.database import db_pool
from app.dal.stored_procedures import sp
from app.utils.logger import logger
from app.utils.exceptions import BusinessError

router = APIRouter()


@router.post("/users", response_model=ResponseModel[dict])
async def add_user(request: AddUserRequest):
    """
    添加用户（学生/教师/教务）
    
    调用存储过程 sp_add_user
    """
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            user_id, message = sp.sp_add_user(
                cursor,
                request.student_id,
                request.name,
                request.password,
                request.role,
                request.department_id
            )
            
            if user_id > 0:
                logger.info(f"添加用户成功: {request.name} ({request.student_id})")
                return ResponseModel(
                    success=True,
                    code=200,
                    message=message,
                    data={"user_id": user_id}
                )
            else:
                raise BusinessError(message)
                
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"添加用户失败: {str(e)}")
        raise


@router.get("/users", response_model=ResponseModel[List[UserResponse]])
async def get_users(
    role: str = Query(None, description="角色筛选：学生/教师/教务"),
    department_id: int = Query(None, description="院系ID筛选")
):
    """
    查询用户列表
    """
    try:
        with db_pool.get_cursor() as cursor:
            # 构建查询SQL
            sql = """
                SELECT 
                    u.`用户ID` as user_id,
                    u.`学号_工号` as student_id,
                    u.`姓名` as name,
                    u.`角色` as role,
                    d.`院系名称` as department_name
                FROM `用户信息表` u
                JOIN `院系信息表` d ON u.`院系ID` = d.`院系ID`
                WHERE 1=1
            """
            params = []
            
            if role:
                sql += " AND u.`角色` = %s"
                params.append(role)
            
            if department_id:
                sql += " AND u.`院系ID` = %s"
                params.append(department_id)
            
            sql += " ORDER BY u.`用户ID` DESC LIMIT 100"
            
            cursor.execute(sql, params)
            results = cursor.fetchall()
            
            users = [
                UserResponse(
                    user_id=r['user_id'],
                    student_id=r['student_id'],
                    name=r['name'],
                    role=r['role'],
                    department_name=r['department_name']
                )
                for r in results
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(users)} 个用户",
                data=users
            )
            
    except Exception as e:
        logger.error(f"查询用户列表失败: {str(e)}")
        raise


@router.post("/courses", response_model=ResponseModel[dict])
async def add_course(request: AddCourseRequest):
    """
    添加课程
    
    调用存储过程 sp_add_course
    """
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            message = sp.sp_add_course(
                cursor,
                request.course_id,
                request.course_name,
                request.credit,
                request.department_id
            )
            
            logger.info(f"添加课程成功: {request.course_name} ({request.course_id})")
            
            return ResponseModel(
                success=True,
                code=200,
                message=message,
                data={"course_id": request.course_id}
            )
                
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"添加课程失败: {str(e)}")
        raise


@router.get("/courses", response_model=ResponseModel[List[CourseResponse]])
async def get_courses(
    department_id: int = Query(None, description="院系ID筛选")
):
    """
    查询课程列表
    """
    try:
        with db_pool.get_cursor() as cursor:
            sql = """
                SELECT 
                    c.`课程ID` as course_id,
                    c.`课程名称` as course_name,
                    c.`学分` as credit,
                    d.`院系名称` as department_name
                FROM `课程信息表` c
                JOIN `院系信息表` d ON c.`院系ID` = d.`院系ID`
                WHERE 1=1
            """
            params = []
            
            if department_id:
                sql += " AND c.`院系ID` = %s"
                params.append(department_id)
            
            sql += " ORDER BY c.`课程ID`"
            
            cursor.execute(sql, params)
            results = cursor.fetchall()
            
            courses = [
                CourseResponse(
                    course_id=r['course_id'],
                    course_name=r['course_name'],
                    credit=float(r['credit']),
                    department_name=r['department_name']
                )
                for r in results
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(courses)} 门课程",
                data=courses
            )
            
    except Exception as e:
        logger.error(f"查询课程列表失败: {str(e)}")
        raise


@router.post("/departments", response_model=ResponseModel[dict])
async def add_department(request: AddDepartmentRequest):
    """
    添加院系
    
    调用存储过程 sp_add_department
    """
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            department_id, message = sp.sp_add_department(
                cursor,
                request.department_name
            )
            
            if department_id > 0:
                logger.info(f"添加院系成功: {request.department_name}")
                return ResponseModel(
                    success=True,
                    code=200,
                    message=message,
                    data={"department_id": department_id}
                )
            else:
                raise BusinessError(message)
                
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"添加院系失败: {str(e)}")
        raise


@router.get("/departments", response_model=ResponseModel[List[DepartmentResponse]])
async def get_departments():
    """
    查询院系列表
    """
    try:
        with db_pool.get_cursor() as cursor:
            sql = """
                SELECT 
                    `院系ID` as department_id,
                    `院系名称` as department_name
                FROM `院系信息表`
                ORDER BY `院系ID`
            """
            
            cursor.execute(sql)
            results = cursor.fetchall()
            
            departments = [
                DepartmentResponse(
                    department_id=r['department_id'],
                    department_name=r['department_name']
                )
                for r in results
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(departments)} 个院系",
                data=departments
            )
            
    except Exception as e:
        logger.error(f"查询院系列表失败: {str(e)}")
        raise


# ==================== 开课管理相关接口 ====================

@router.get("/classrooms", response_model=ResponseModel[List[ClassroomResponse]])
async def get_classrooms():
    """
    获取教室列表
    """
    try:
        with db_pool.get_cursor() as cursor:
            sql = """
                SELECT 
                    `教室ID` as classroom_id,
                    `教学楼` as building,
                    `房间号` as room_number,
                    `容量` as capacity
                FROM `教室信息表`
                ORDER BY `教学楼`, `房间号`
            """
            
            cursor.execute(sql)
            results = cursor.fetchall()
            
            classrooms = [
                ClassroomResponse(
                    classroom_id=r['classroom_id'],
                    building=r['building'],
                    room_number=r['room_number'],
                    capacity=r['capacity']
                )
                for r in results
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(classrooms)} 个教室",
                data=classrooms
            )
            
    except Exception as e:
        logger.error(f"查询教室列表失败: {str(e)}")
        raise


@router.get("/semesters", response_model=ResponseModel[List[SemesterResponse]])
async def get_semesters():
    """
    获取学期列表
    """
    try:
        with db_pool.get_cursor() as cursor:
            sql = """
                SELECT 
                    `学期ID` as semester_id,
                    CONCAT(`学年`, ' ', `学期类型`) as semester_name
                FROM `学期信息表`
                ORDER BY `学期ID` DESC
            """
            
            cursor.execute(sql)
            results = cursor.fetchall()
            
            semesters = [
                SemesterResponse(
                    semester_id=r['semester_id'],
                    semester_name=r['semester_name']
                )
                for r in results
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(semesters)} 个学期",
                data=semesters
            )
            
    except Exception as e:
        logger.error(f"查询学期列表失败: {str(e)}")
        raise


@router.post("/instances", response_model=ResponseModel[dict])
async def create_instance(request: CreateInstanceRequest):
    """
    创建开课实例（包含教师和时间段）
    
    流程:
    1. 调用 sp_create_course_instance 创建开课实例
    2. 循环调用 sp_assign_teacher 分配教师
    3. 循环调用 sp_add_schedule_time 添加上课时间
    """
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            # 步骤1: 创建开课实例
            instance_id, message = sp.sp_create_course_instance(
                cursor,
                request.course_id,
                request.classroom_id,
                request.semester_id,
                request.quota_inner,
                request.quota_outer
            )
            
            logger.info(f"创建开课实例成功: instance_id={instance_id}, {message}")
            
            # 步骤2: 分配教师
            for teacher_id in request.teachers:
                teacher_message = sp.sp_assign_teacher(cursor, teacher_id, instance_id)
                logger.info(f"分配教师: teacher_id={teacher_id}, {teacher_message}")
            
            # 步骤3: 添加上课时间
            for time_slot in request.time_slots:
                # 计算时间段ID: (星期-1) * 5 + 时间段
                timeslot_id = (time_slot.weekday - 1) * 5 + time_slot.time_slot
                
                schedule_id, schedule_message = sp.sp_add_schedule_time(
                    cursor,
                    instance_id,
                    timeslot_id,
                    time_slot.teacher_id,
                    time_slot.start_week,
                    time_slot.end_week,
                    time_slot.week_type
                )
                logger.info(f"添加上课时间: schedule_id={schedule_id}, {schedule_message}")
            
            return ResponseModel(
                success=True,
                code=200,
                message="开课实例创建成功",
                data={
                    "instance_id": instance_id,
                    "teachers_count": len(request.teachers),
                    "timeslots_count": len(request.time_slots)
                }
            )
            
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"创建开课实例失败: {str(e)}")
        raise


@router.get("/instances", response_model=ResponseModel[List[CourseInstanceResponse]])
async def get_instances(
    semester_id: int = Query(None, description="学期ID筛选")
):
    """
    获取开课实例列表
    """
    try:
        with db_pool.get_cursor() as cursor:
            sql = """
                SELECT 
                    i.`开课实例ID` as instance_id,
                    c.`课程ID` as course_id,
                    c.`课程名称` as course_name,
                    CONCAT(s.`学年`, ' ', s.`学期类型`) as semester_name,
                    r.`教学楼` as building,
                    r.`房间号` as room_number,
                    i.`对内名额` as quota_inner,
                    i.`对外名额` as quota_outer,
                    i.`已选对内人数` as enrolled_inner,
                    i.`已选对外人数` as enrolled_outer,
                    GROUP_CONCAT(DISTINCT u.`姓名` ORDER BY u.`姓名` SEPARATOR ', ') as teachers
                FROM `开课实例表` i
                JOIN `课程信息表` c ON i.`课程ID` = c.`课程ID`
                JOIN `学期信息表` s ON i.`学期ID` = s.`学期ID`
                JOIN `教室信息表` r ON i.`教室ID` = r.`教室ID`
                LEFT JOIN `授课关系表` t ON i.`开课实例ID` = t.`开课实例ID`
                LEFT JOIN `用户信息表` u ON t.`教师ID` = u.`用户ID`
                WHERE 1=1
            """
            params = []
            
            if semester_id:
                sql += " AND i.`学期ID` = %s"
                params.append(semester_id)
            
            sql += " GROUP BY i.`开课实例ID` ORDER BY i.`开课实例ID` DESC LIMIT 100"
            
            cursor.execute(sql, params)
            results = cursor.fetchall()
            
            instances = [
                CourseInstanceResponse(
                    instance_id=r['instance_id'],
                    course_id=r['course_id'],
                    course_name=r['course_name'],
                    semester_name=r['semester_name'],
                    building=r['building'],
                    room_number=r['room_number'],
                    quota_inner=r['quota_inner'],
                    quota_outer=r['quota_outer'],
                    enrolled_inner=r['enrolled_inner'],
                    enrolled_outer=r['enrolled_outer'],
                    teachers=r['teachers'] or ''
                )
                for r in results
            ]
            
            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(instances)} 个开课实例",
                data=instances
            )
            
    except Exception as e:
        logger.error(f"查询开课实例列表失败: {str(e)}")
        raise
