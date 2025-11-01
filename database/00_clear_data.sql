-- 00_clear_data.sql
-- 仅清空数据，保留表结构、视图、触发器、存储过程
-- 适合重置测试数据

SET FOREIGN_KEY_CHECKS = 0;

-- 清空所有表数据（按外键依赖顺序）
TRUNCATE TABLE `上课时间表`;
TRUNCATE TABLE `选课记录表`;
TRUNCATE TABLE `授课关系表`;
TRUNCATE TABLE `开课实例表`;
TRUNCATE TABLE `用户信息表`;
TRUNCATE TABLE `课程信息表`;
TRUNCATE TABLE `学期信息表`;
TRUNCATE TABLE `时间段信息表`;
TRUNCATE TABLE `教室信息表`;
TRUNCATE TABLE `院系信息表`;

SET FOREIGN_KEY_CHECKS = 1;
