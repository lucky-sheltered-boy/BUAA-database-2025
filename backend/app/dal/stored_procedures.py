"""
存储过程调用封装
直接调用数据库中已有的 14 个存储过程
"""
from typing import Tuple, Optional
import pymysql
from app.utils.logger import logger
from app.utils.exceptions import DatabaseError, BusinessError


class StoredProcedures:
    """存储过程调用类"""
    
    @staticmethod
    def sp_add_department(cursor, name: str) -> Tuple[int, str]:
        """
        调用 sp_add_department 存储过程
        
        Returns:
            (department_id, message)
        """
        try:
            cursor.callproc('sp_add_department', (name, 0, ''))
            cursor.execute('SELECT @_sp_add_department_1, @_sp_add_department_2')
            result = cursor.fetchone()
            return result['@_sp_add_department_1'], result['@_sp_add_department_2']
        except pymysql.Error as e:
            logger.error(f"调用 sp_add_department 失败: {e}")
            raise DatabaseError(f"添加院系失败: {str(e)}")
    
    @staticmethod
    def sp_add_classroom(cursor, building: str, room: str, capacity: int) -> Tuple[int, str]:
        """
        调用 sp_add_classroom 存储过程
        
        Returns:
            (classroom_id, message)
        """
        try:
            cursor.callproc('sp_add_classroom', (building, room, capacity, 0, ''))
            cursor.execute('SELECT @_sp_add_classroom_3, @_sp_add_classroom_4')
            result = cursor.fetchone()
            return result['@_sp_add_classroom_3'], result['@_sp_add_classroom_4']
        except pymysql.Error as e:
            logger.error(f"调用 sp_add_classroom 失败: {e}")
            raise DatabaseError(f"添加教室失败: {str(e)}")
    
    @staticmethod
    def sp_add_course(cursor, course_id: str, name: str, credit: float, dept_id: int) -> str:
        """
        调用 sp_add_course 存储过程
        
        Returns:
            message
        """
        try:
            cursor.callproc('sp_add_course', (course_id, name, credit, dept_id, ''))
            cursor.execute('SELECT @_sp_add_course_4')
            result = cursor.fetchone()
            return result['@_sp_add_course_4']
        except pymysql.Error as e:
            logger.error(f"调用 sp_add_course 失败: {e}")
            raise DatabaseError(f"添加课程失败: {str(e)}")
    
    @staticmethod
    def sp_add_user(cursor, username: str, name: str, password: str, 
                   role: str, dept_id: int) -> Tuple[int, str]:
        """
        调用 sp_add_user 存储过程
        
        Returns:
            (user_id, message)
        """
        try:
            cursor.callproc('sp_add_user', (username, name, password, role, dept_id, 0, ''))
            cursor.execute('SELECT @_sp_add_user_5, @_sp_add_user_6')
            result = cursor.fetchone()
            return result['@_sp_add_user_5'], result['@_sp_add_user_6']
        except pymysql.Error as e:
            logger.error(f"调用 sp_add_user 失败: {e}")
            raise DatabaseError(f"添加用户失败: {str(e)}")
    
    @staticmethod
    def sp_create_course_instance(cursor, course_id: str, classroom_id: int, 
                                  semester_id: int, quota_inner: int, 
                                  quota_outer: int) -> Tuple[int, str]:
        """
        调用 sp_create_course_instance 存储过程
        
        Returns:
            (instance_id, message)
        """
        try:
            cursor.callproc('sp_create_course_instance', 
                          (course_id, classroom_id, semester_id, quota_inner, quota_outer, 0, ''))
            cursor.execute('SELECT @_sp_create_course_instance_5, @_sp_create_course_instance_6')
            result = cursor.fetchone()
            instance_id = result['@_sp_create_course_instance_5']
            message = result['@_sp_create_course_instance_6']
            
            # 检查是否成功
            if instance_id == -1:
                raise BusinessError(message)
            
            return instance_id, message
        except pymysql.Error as e:
            logger.error(f"调用 sp_create_course_instance 失败: {e}")
            raise DatabaseError(f"创建开课实例失败: {str(e)}")
    
    @staticmethod
    def sp_assign_teacher(cursor, teacher_id: int, instance_id: int) -> str:
        """
        调用 sp_assign_teacher 存储过程
        
        Returns:
            message
        """
        try:
            cursor.callproc('sp_assign_teacher', (teacher_id, instance_id, ''))
            cursor.execute('SELECT @_sp_assign_teacher_2')
            result = cursor.fetchone()
            message = result['@_sp_assign_teacher_2']
            
            if '失败' in message:
                raise BusinessError(message)
            
            return message
        except pymysql.Error as e:
            logger.error(f"调用 sp_assign_teacher 失败: {e}")
            raise DatabaseError(f"分配教师失败: {str(e)}")
    
    @staticmethod
    def sp_add_schedule_time(cursor, instance_id: int, timeslot_id: int, 
                            teacher_id: Optional[int], start_week: int, 
                            end_week: int, week_type: str) -> Tuple[int, str]:
        """
        调用 sp_add_schedule_time 存储过程
        
        Returns:
            (schedule_id, message)
        """
        try:
            cursor.callproc('sp_add_schedule_time', 
                          (instance_id, timeslot_id, teacher_id, start_week, end_week, week_type, 0, ''))
            cursor.execute('SELECT @_sp_add_schedule_time_6, @_sp_add_schedule_time_7')
            result = cursor.fetchone()
            schedule_id = result['@_sp_add_schedule_time_6']
            message = result['@_sp_add_schedule_time_7']
            
            if schedule_id == -1:
                raise BusinessError(message)
            
            return schedule_id, message
        except pymysql.Error as e:
            logger.error(f"调用 sp_add_schedule_time 失败: {e}")
            raise DatabaseError(f"添加上课时间失败: {str(e)}")
    
    @staticmethod
    def sp_student_enroll(cursor, student_id: int, instance_id: int) -> str:
        """
        调用 sp_student_enroll 存储过程 - 学生选课
        
        Returns:
            message
        """
        try:
            # 调用存储过程
            cursor.callproc('sp_student_enroll', (student_id, instance_id, ''))
            
            # 获取输出参数
            cursor.execute('SELECT @_sp_student_enroll_2')
            result = cursor.fetchone()
            message = result['@_sp_student_enroll_2']
            
            # 检查是否成功
            if '失败' in message or 'ERROR' in message.upper():
                raise BusinessError(message)
            
            return message
            
        except pymysql.Error as e:
            error_msg = str(e)
            logger.error(f"调用 sp_student_enroll 失败: {error_msg}")
            
            # 解析触发器抛出的错误
            if 'SIGNAL' in error_msg or '45000' in error_msg:
                # 提取错误消息
                if '名额已满' in error_msg:
                    raise BusinessError("选课失败: 名额已满")
                elif '时间冲突' in error_msg:
                    raise BusinessError("选课失败: 上课时间冲突")
                elif '已选过' in error_msg:
                    raise BusinessError("选课失败: 已选过该课程")
                elif '不在选课时间' in error_msg:
                    raise BusinessError("选课失败: 不在选课时间窗口内")
                else:
                    raise BusinessError(f"选课失败: {error_msg}")
            
            raise DatabaseError(f"选课操作失败: {error_msg}")
    
    @staticmethod
    def sp_student_drop(cursor, student_id: int, instance_id: int) -> str:
        """
        调用 sp_student_drop 存储过程 - 学生退课
        
        Returns:
            message
        """
        try:
            cursor.callproc('sp_student_drop', (student_id, instance_id, ''))
            cursor.execute('SELECT @_sp_student_drop_2')
            result = cursor.fetchone()
            message = result['@_sp_student_drop_2']
            
            if '失败' in message:
                raise BusinessError(message)
            
            return message
        except pymysql.Error as e:
            logger.error(f"调用 sp_student_drop 失败: {e}")
            raise DatabaseError(f"退课失败: {str(e)}")
    
    @staticmethod
    def sp_get_student_schedule(cursor, student_id: int, semester_id: int) -> list:
        """
        调用 sp_get_student_schedule 存储过程 - 查询学生课表
        
        Returns:
            课表列表
        """
        try:
            cursor.callproc('sp_get_student_schedule', (student_id, semester_id))
            results = cursor.fetchall()
            return results
        except pymysql.Error as e:
            logger.error(f"调用 sp_get_student_schedule 失败: {e}")
            raise DatabaseError(f"查询学生课表失败: {str(e)}")
    
    @staticmethod
    def sp_get_teacher_schedule(cursor, teacher_id: int, semester_id: int) -> list:
        """
        调用 sp_get_teacher_schedule 存储过程 - 查询教师课表
        
        Returns:
            课表列表
        """
        try:
            cursor.callproc('sp_get_teacher_schedule', (teacher_id, semester_id))
            results = cursor.fetchall()
            return results
        except pymysql.Error as e:
            logger.error(f"调用 sp_get_teacher_schedule 失败: {e}")
            raise DatabaseError(f"查询教师课表失败: {str(e)}")
    
    @staticmethod
    def sp_get_available_courses(cursor, student_id: int) -> list:
        """
        调用 sp_get_available_courses 存储过程 - 查询可选课程
        
        Returns:
            可选课程列表
        """
        try:
            cursor.callproc('sp_get_available_courses', (student_id,))
            results = cursor.fetchall()
            return results
        except pymysql.Error as e:
            logger.error(f"调用 sp_get_available_courses 失败: {e}")
            raise DatabaseError(f"查询可选课程失败: {str(e)}")
    
    @staticmethod
    def sp_get_enrollment_statistics(cursor, semester_id: int) -> list:
        """
        调用 sp_get_enrollment_statistics 存储过程 - 查询选课统计
        
        Returns:
            统计结果列表
        """
        try:
            cursor.callproc('sp_get_enrollment_statistics', (semester_id,))
            results = cursor.fetchall()
            return results
        except pymysql.Error as e:
            logger.error(f"调用 sp_get_enrollment_statistics 失败: {e}")
            raise DatabaseError(f"查询选课统计失败: {str(e)}")


# 全局实例
sp = StoredProcedures()
