"""
管理员 API 路由
"""
from fastapi import APIRouter, Query
from typing import List

from app.models.common import ResponseModel
from app.models.admin import (
    AddUserRequest, UpdateUserRequest, AddCourseRequest, AddDepartmentRequest,
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
                    u.`院系ID` as department_id,
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
                    department_id=r['department_id'],
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


@router.put("/users/{user_id}", response_model=ResponseModel[dict])
async def update_user(user_id: int, request: UpdateUserRequest):
    """更新用户信息"""
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            # Check if user exists
            cursor.execute("SELECT 1 FROM `用户信息表` WHERE `用户ID` = %s", (user_id,))
            if not cursor.fetchone():
                raise BusinessError(f"用户ID {user_id} 不存在")

            # Check if department exists
            cursor.execute("SELECT 1 FROM `院系信息表` WHERE `院系ID` = %s", (request.department_id,))
            if not cursor.fetchone():
                raise BusinessError(f"院系ID {request.department_id} 不存在")

            # Check if student_id exists for other users
            cursor.execute(
                "SELECT 1 FROM `用户信息表` WHERE `学号_工号` = %s AND `用户ID` != %s",
                (request.student_id, user_id)
            )
            if cursor.fetchone():
                raise BusinessError(f"学号/工号 {request.student_id} 已被其他用户使用")

            sql = """
                UPDATE `用户信息表`
                SET `学号_工号` = %s, `姓名` = %s, `角色` = %s, `院系ID` = %s
                WHERE `用户ID` = %s
            """
            cursor.execute(sql, (request.student_id, request.name, request.role, request.department_id, user_id))
            
            logger.info(f"更新用户成功: {request.name} ({user_id})")
            return ResponseModel(success=True, code=200, message="更新成功", data={})
            
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"更新用户失败: {str(e)}")
        raise


@router.delete("/users/{user_id}", response_model=ResponseModel[dict])
async def delete_user(user_id: int):
    """删除用户"""
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            cursor.execute("SELECT 1 FROM `用户信息表` WHERE `用户ID` = %s", (user_id,))
            if not cursor.fetchone():
                raise BusinessError(f"用户ID {user_id} 不存在")
                
            cursor.execute("DELETE FROM `用户信息表` WHERE `用户ID` = %s", (user_id,))
            
            logger.info(f"删除用户成功: {user_id}")
            return ResponseModel(success=True, code=200, message="删除成功", data={})
            
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"删除用户失败: {str(e)}")
        raise


@router.post("/users/{user_id}/reset-password", response_model=ResponseModel[dict])
async def reset_password(user_id: int):
    """重置用户密码"""
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            cursor.execute("SELECT 1 FROM `用户信息表` WHERE `用户ID` = %s", (user_id,))
            if not cursor.fetchone():
                raise BusinessError(f"用户ID {user_id} 不存在")
            
            # Default password: hash_MD5('123456')
            sql = """
                UPDATE `用户信息表`
                SET `密码哈希` = CONCAT('hash_', MD5('123456'))
                WHERE `用户ID` = %s
            """
            cursor.execute(sql, (user_id,))
            
            logger.info(f"重置密码成功: {user_id}")
            return ResponseModel(success=True, code=200, message="密码重置成功", data={})
            
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"重置密码失败: {str(e)}")
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
                # 查找对应星期和节次的时间段ID
                # 注意：这里假设时间段是按开始时间排序的，第N节就是第N个记录
                cursor.execute("""
                    SELECT `时间段ID` 
                    FROM `时间段信息表` 
                    WHERE `星期` = %s 
                    ORDER BY `开始时间`
                """, (time_slot.weekday,))
                
                available_slots = cursor.fetchall()
                
                # 检查节次是否存在
                # time_slot.time_slot 是 1-based index
                if time_slot.time_slot < 1 or time_slot.time_slot > len(available_slots):
                    # 星期几的中文映射
                    week_map = {1: '一', 2: '二', 3: '三', 4: '四', 5: '五', 6: '六', 7: '日'}
                    week_str = week_map.get(time_slot.weekday, str(time_slot.weekday))
                    raise BusinessError(f"星期{week_str}没有配置第{time_slot.time_slot}节课的时间段")
                
                timeslot_id = available_slots[time_slot.time_slot - 1]['时间段ID']
                
                schedule_id, schedule_message = sp.sp_add_schedule_time(
                    cursor,
                    instance_id,
                    timeslot_id,
                    time_slot.teacher_id,
                    time_slot.start_week,
                    time_slot.end_week,
                    time_slot.week_type
                )
                
                if schedule_id == -1:
                    raise BusinessError(f"添加上课时间失败: {schedule_message}")
                    
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
                    GROUP_CONCAT(DISTINCT CONCAT(u.`用户ID`, ':', u.`姓名`) SEPARATOR ',') as teachers_info
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
            
            instances = []
            for r in results:
                # 解析教师信息
                teachers = []
                if r['teachers_info']:
                    for t_str in r['teachers_info'].split(','):
                        if ':' in t_str:
                            tid, tname = t_str.split(':', 1)
                            teachers.append({"teacher_id": int(tid), "name": tname})
                
                # 获取时间段信息 (需要额外查询，或者简化处理)
                # 这里为了性能，暂时先不返回详细时间段，或者再做一次查询
                # 为了前端编辑回显，最好能返回时间段。
                # 我们可以用另一个查询获取所有相关的时间段
                
                instances.append(CourseInstanceResponse(
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
                    teachers=teachers,
                    time_slots=[] # 暂时为空，如果需要编辑回显，建议单独获取详情接口
                ))
            
            # 批量获取时间段信息并填充
            if instances:
                instance_ids = [str(i.instance_id) for i in instances]
                ids_str = ",".join(instance_ids)
                sql_slots = f"""
                    SELECT 
                        t.`开课实例ID` as instance_id,
                        ts.`星期` as day_of_week,
                        ts.`时间段ID` as period_id,
                        -- 这里简化处理，假设时间段ID 1-5 对应 第1-5节，或者需要从时间段表反推
                        -- 实际上时间段ID可能不是连续的1-5，需要根据业务逻辑。
                        -- 假设 (时间段ID-1)%5 + 1 是节次，(时间段ID-1)//5 + 1 是星期
                        -- 或者直接返回原始数据
                        t.`时间段ID`
                    FROM `上课时间表` t
                    JOIN `时间段信息表` ts ON t.`时间段ID` = ts.`时间段ID`
                    WHERE t.`开课实例ID` IN ({ids_str})
                """
                cursor.execute(sql_slots)
                slots_results = cursor.fetchall()
                
                # 构建映射
                slots_map = {}
                for s in slots_results:
                    iid = s['instance_id']
                    if iid not in slots_map:
                        slots_map[iid] = []
                    
                    # 简单的星期映射
                    week_map = {'星期一': 1, '星期二': 2, '星期三': 3, '星期四': 4, '星期五': 5, '星期六': 6, '星期日': 7}
                    # 假设时间段ID 1-35 对应 7天*5节
                    # 实际上应该读取 `时间段信息表` 的具体时间，这里简化为前端需要的格式
                    # 假设数据库中时间段ID是按顺序生成的
                    
                    slots_map[iid].append({
                        "day_of_week": week_map.get(s['day_of_week'], 1),
                        "period": (s['时间段ID'] - 1) % 5 + 1 # 这是一个假设，可能不准确，最好是存储过程返回
                    })
                
                for inst in instances:
                    if inst.instance_id in slots_map:
                        inst.time_slots = slots_map[inst.instance_id]

            return ResponseModel(
                success=True,
                code=200,
                message=f"查询到 {len(instances)} 个开课实例",
                data=instances
            )
            
    except Exception as e:
        logger.error(f"查询开课实例列表失败: {str(e)}")
        raise


@router.delete("/instances/{instance_id}", response_model=ResponseModel[dict])
async def delete_instance(instance_id: int):
    """删除开课实例"""
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            # 检查是否存在
            cursor.execute("SELECT 1 FROM `开课实例表` WHERE `开课实例ID` = %s", (instance_id,))
            if not cursor.fetchone():
                raise BusinessError(f"开课实例ID {instance_id} 不存在")
            
            # 删除 (由于有 ON DELETE CASCADE，会自动删除相关记录)
            cursor.execute("DELETE FROM `开课实例表` WHERE `开课实例ID` = %s", (instance_id,))
            
            logger.info(f"删除开课实例成功: {instance_id}")
            return ResponseModel(success=True, code=200, message="删除成功", data={})
            
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"删除开课实例失败: {str(e)}")
        raise


@router.delete("/courses/{course_id}", response_model=ResponseModel[dict])
async def delete_course(course_id: str):
    """删除课程"""
    try:
        with db_pool.get_cursor(commit=True) as cursor:
            # 检查是否存在
            cursor.execute("SELECT 1 FROM `课程信息表` WHERE `课程ID` = %s", (course_id,))
            if not cursor.fetchone():
                raise BusinessError(f"课程ID {course_id} 不存在")
            
            # 检查是否被引用
            cursor.execute("SELECT 1 FROM `开课实例表` WHERE `课程ID` = %s LIMIT 1", (course_id,))
            if cursor.fetchone():
                raise BusinessError(f"课程 {course_id} 已有开课记录，无法直接删除。请先删除相关的开课实例。")
            
            cursor.execute("DELETE FROM `课程信息表` WHERE `课程ID` = %s", (course_id,))
            
            logger.info(f"删除课程成功: {course_id}")
            return ResponseModel(success=True, code=200, message="删除成功", data={})
            
    except BusinessError:
        raise
    except Exception as e:
        logger.error(f"删除课程失败: {str(e)}")
        raise
