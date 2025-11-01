-- 00_clear_all.sql
-- 清空所有表、视图、触发器、存储过程（01-04文件创建的对象）
-- 执行本文件可一键清理数据库，适合重建/重置环境

SET FOREIGN_KEY_CHECKS = 0;

-- 1. 删除所有视图
DROP VIEW IF EXISTS `当前学期开课实例视图`;
DROP VIEW IF EXISTS `学生选课详情视图`;
DROP VIEW IF EXISTS `教师授课详情视图`;

-- 2. 删除所有触发器
DROP TRIGGER IF EXISTS `trg_before_enroll_check`;
DROP TRIGGER IF EXISTS `trg_after_enroll_update_count`;
DROP TRIGGER IF EXISTS `trg_after_drop_update_count`;
DROP TRIGGER IF EXISTS `trg_before_schedule_check_teacher`;
DROP TRIGGER IF EXISTS `trg_before_schedule_check_room`;
DROP TRIGGER IF EXISTS `trg_before_schedule_update_check_teacher`;
DROP TRIGGER IF EXISTS `trg_before_schedule_update_check_room`;
DROP TRIGGER IF EXISTS `trg_before_enroll_update_prevent`;
DROP TRIGGER IF EXISTS `trg_before_course_instance_delete_check`;
DROP TRIGGER IF EXISTS `trg_before_course_instance_check_capacity`;
DROP TRIGGER IF EXISTS `trg_before_course_instance_update_check_capacity`;

-- 3. 删除所有存储过程
DROP PROCEDURE IF EXISTS `sp_add_department`;
DROP PROCEDURE IF EXISTS `sp_add_classroom`;
DROP PROCEDURE IF EXISTS `sp_add_course`;
DROP PROCEDURE IF EXISTS `sp_add_user`;
DROP PROCEDURE IF EXISTS `sp_create_course_instance`;
DROP PROCEDURE IF EXISTS `sp_assign_teacher`;
DROP PROCEDURE IF EXISTS `sp_add_schedule_time`;
DROP PROCEDURE IF EXISTS `sp_student_enroll`;
DROP PROCEDURE IF EXISTS `sp_student_drop`;
DROP PROCEDURE IF EXISTS `sp_get_student_schedule`;
DROP PROCEDURE IF EXISTS `sp_get_teacher_schedule`;
DROP PROCEDURE IF EXISTS `sp_get_available_courses`;
DROP PROCEDURE IF EXISTS `sp_batch_add_students`;
DROP PROCEDURE IF EXISTS `sp_get_enrollment_statistics`;

-- 4. 删除所有表（含外键依赖顺序）
DROP TABLE IF EXISTS `上课时间表`;
DROP TABLE IF EXISTS `选课记录表`;
DROP TABLE IF EXISTS `授课关系表`;
DROP TABLE IF EXISTS `开课实例表`;
DROP TABLE IF EXISTS `用户信息表`;
DROP TABLE IF EXISTS `课程信息表`;
DROP TABLE IF EXISTS `学期信息表`;
DROP TABLE IF EXISTS `时间段信息表`;
DROP TABLE IF EXISTS `教室信息表`;
DROP TABLE IF EXISTS `院系信息表`;

SET FOREIGN_KEY_CHECKS = 1;
