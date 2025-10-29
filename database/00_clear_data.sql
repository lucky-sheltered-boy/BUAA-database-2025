-- 快速清理测试数据脚本

SET FOREIGN_KEY_CHECKS = 0;

-- 按依赖关系逆序删除数据
TRUNCATE TABLE `选课记录表`;
TRUNCATE TABLE `上课时间表`;
TRUNCATE TABLE `授课关系表`;
TRUNCATE TABLE `开课实例表`;
TRUNCATE TABLE `用户信息表`;
TRUNCATE TABLE `课程信息表`;
TRUNCATE TABLE `学期信息表`;
TRUNCATE TABLE `时间段信息表`;
TRUNCATE TABLE `教室信息表`;
TRUNCATE TABLE `院系信息表`;

SET FOREIGN_KEY_CHECKS = 1;

-- 验证清理结果
SELECT '院系信息表' AS 表名, COUNT(*) AS 记录数 FROM `院系信息表`
UNION ALL
SELECT '教室信息表', COUNT(*) FROM `教室信息表`
UNION ALL
SELECT '时间段信息表', COUNT(*) FROM `时间段信息表`
UNION ALL
SELECT '学期信息表', COUNT(*) FROM `学期信息表`
UNION ALL
SELECT '课程信息表', COUNT(*) FROM `课程信息表`
UNION ALL
SELECT '用户信息表', COUNT(*) FROM `用户信息表`
UNION ALL
SELECT '开课实例表', COUNT(*) FROM `开课实例表`
UNION ALL
SELECT '授课关系表', COUNT(*) FROM `授课关系表`
UNION ALL
SELECT '上课时间表', COUNT(*) FROM `上课时间表`
UNION ALL
SELECT '选课记录表', COUNT(*) FROM `选课记录表`;