-- 完整的清理和重建脚本

SET NAMES utf8mb4;

-- 第一步: 删除所有存储过程

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


-- 第二步: 删除所有触发器

-- 选课相关触发器
DROP TRIGGER IF EXISTS `trg_before_enroll_check`;
DROP TRIGGER IF EXISTS `trg_after_enroll_update_count`;
DROP TRIGGER IF EXISTS `trg_after_drop_update_count`;

-- 排课相关触发器
DROP TRIGGER IF EXISTS `trg_before_schedule_check_teacher`;
DROP TRIGGER IF EXISTS `trg_before_schedule_check_room`;
DROP TRIGGER IF EXISTS `trg_before_schedule_update_check_teacher`;
DROP TRIGGER IF EXISTS `trg_before_schedule_update_check_room`;

-- 数据一致性触发器
DROP TRIGGER IF EXISTS `trg_before_enroll_update_prevent`;
DROP TRIGGER IF EXISTS `trg_before_course_instance_delete_check`;
DROP TRIGGER IF EXISTS `trg_before_course_instance_check_capacity`;
DROP TRIGGER IF EXISTS `trg_before_course_instance_update_check_capacity`;


-- 第三步: 删除所有视图

DROP VIEW IF EXISTS `当前学期开课实例视图`;
DROP VIEW IF EXISTS `学生选课详情视图`;
DROP VIEW IF EXISTS `教师授课详情视图`;


-- 第四步: 删除所有表

SET FOREIGN_KEY_CHECKS = 0;

-- 联系表
DROP TABLE IF EXISTS `选课记录表`;
DROP TABLE IF EXISTS `授课关系表`;
DROP TABLE IF EXISTS `上课时间表`;

-- 核心表
DROP TABLE IF EXISTS `开课实例表`;

-- 基础实体表
DROP TABLE IF EXISTS `课程信息表`;
DROP TABLE IF EXISTS `用户信息表`;
DROP TABLE IF EXISTS `学期信息表`;
DROP TABLE IF EXISTS `时间段信息表`;
DROP TABLE IF EXISTS `教室信息表`;
DROP TABLE IF EXISTS `院系信息表`;

SET FOREIGN_KEY_CHECKS = 1;


-- 检查剩余的表
SELECT COUNT(*) AS '剩余表数量' 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_TYPE = 'BASE TABLE';

-- 检查剩余的视图
SELECT COUNT(*) AS '剩余视图数量' 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_TYPE = 'VIEW';

-- 检查剩余的触发器
SELECT COUNT(*) AS '剩余触发器数量' 
FROM information_schema.TRIGGERS 
WHERE TRIGGER_SCHEMA = DATABASE();

-- 检查剩余的存储过程
SELECT COUNT(*) AS '剩余存储过程数量' 
FROM information_schema.ROUTINES 
WHERE ROUTINE_SCHEMA = DATABASE() 
  AND ROUTINE_TYPE = 'PROCEDURE';