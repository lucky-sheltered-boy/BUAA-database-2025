"""
管理员 API 路由
"""
from fastapi import APIRouter, Query
from typing import List

from app.models.common import ResponseModel
from app.models.admin import (
    AddUserRequest, AddCourseRequest, AddDepartmentRequest,
    UserResponse, CourseResponse, DepartmentResponse
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
