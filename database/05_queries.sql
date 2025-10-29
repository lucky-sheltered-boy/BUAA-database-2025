-- 查询示例脚本

SET NAMES utf8mb4;

-- 1. 基础CRUD操作示例

-- ==================== CREATE (插入) ====================

-- 1.1 插入新院系
INSERT INTO `院系信息表` (`院系名称`) 
VALUES ('人工智能学院');

-- 1.2 插入新教室
INSERT INTO `教室信息表` (`教学楼`, `房间号`, `容量`) 
VALUES ('智能楼', '501', 80);

-- 1.3 插入新课程
INSERT INTO `课程信息表` (`课程ID`, `课程名称`, `学分`, `院系ID`) 
VALUES ('AI101', '机器学习基础', 4.0, 1);

-- 1.4 插入新用户(学生)
INSERT INTO `用户信息表` (`学号_工号`, `姓名`, `密码哈希`, `角色`, `院系ID`) 
VALUES ('2024050', '李新生', 'hash_123456', '学生', 1);

-- 1.5 创建新学期
INSERT INTO `学期信息表` (`学年`, `学期`, `选课开始时间`, `选课结束时间`, `是否当前学期`) 
VALUES ('2024-2025', '秋', '2024-09-01 00:00:00', '2024-09-15 23:59:59', FALSE);


-- ==================== READ (查询) ====================

-- 1.6 查询所有院系
SELECT * FROM `院系信息表`;

-- 1.7 查询所有教室及其容量
SELECT `教学楼`, `房间号`, `容量` 
FROM `教室信息表`
ORDER BY `教学楼`, `房间号`;

-- 1.8 查询某院系的所有课程
SELECT `课程ID`, `课程名称`, `学分` 
FROM `课程信息表`
WHERE `院系ID` = 1
ORDER BY `课程ID`;

-- 1.9 查询所有学生信息
SELECT `用户ID`, `学号_工号`, `姓名`, d.`院系名称`
FROM `用户信息表` u
JOIN `院系信息表` d ON u.`院系ID` = d.`院系ID`
WHERE u.`角色` = '学生'
ORDER BY `学号_工号`;

-- 1.10 查询当前学期信息
SELECT * FROM `学期信息表`
WHERE `是否当前学期` = TRUE;


-- ==================== UPDATE (修改) ====================

-- 1.11 修改教室容量
UPDATE `教室信息表`
SET `容量` = 150
WHERE `教学楼` = '理科楼' AND `房间号` = '101';

-- 1.12 修改课程学分
UPDATE `课程信息表`
SET `学分` = 3.5
WHERE `课程ID` = 'CS101';

-- 1.13 修改用户密码
UPDATE `用户信息表`
SET `密码哈希` = 'hash_newpassword'
WHERE `学号_工号` = '2024001';

-- 1.14 更新开课实例名额
UPDATE `开课实例表`
SET `对内名额` = 35, `对外名额` = 15
WHERE `开课实例ID` = 1;

-- 1.15 切换当前学期
UPDATE `学期信息表`
SET `是否当前学期` = TRUE
WHERE `学期ID` = 2;


-- ==================== DELETE (删除) ====================

-- 1.16 删除选课记录(退课)
DELETE FROM `选课记录表`
WHERE `学生ID` = 1 AND `开课实例ID` = 1;

-- 1.17 删除未使用的教室
DELETE FROM `教室信息表`
WHERE `教室ID` NOT IN (SELECT DISTINCT `教室ID` FROM `开课实例表`);

-- 1.18 删除未开课的课程
DELETE FROM `课程信息表`
WHERE `课程ID` NOT IN (SELECT DISTINCT `课程ID` FROM `开课实例表`);

-- 1.19 删除授课关系
DELETE FROM `授课关系表`
WHERE `教师ID` = 2 AND `开课实例ID` = 1;

-- 1.20 删除上课时间
DELETE FROM `上课时间表`
WHERE `上课时间ID` = 1;


-- 2. 复杂查询示例

-- ==================== 多表联合查询 ====================

-- 2.1 查询完整的课程信息(含院系、教室、学期)
SELECT 
    c.`课程ID`,
    c.`课程名称`,
    c.`学分`,
    d.`院系名称` AS `开课院系`,
    CONCAT(r.`教学楼`, ' ', r.`房间号`) AS `上课地点`,
    r.`容量` AS `教室容量`,
    s.`学年`,
    s.`学期`,
    oi.`对内名额`,
    oi.`对外名额`,
    oi.`已选对内人数`,
    oi.`已选对外人数`,
    (oi.`已选对内人数` + oi.`已选对外人数`) AS `总选课人数`
FROM `开课实例表` oi
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `院系信息表` d ON c.`院系ID` = d.`院系ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`
WHERE s.`是否当前学期` = TRUE
ORDER BY c.`课程ID`;

-- 2.2 查询学生的完整课表(含教师、教室、时间、周次)
SELECT 
    u.`学号_工号`,
    u.`姓名` AS `学生姓名`,
    c.`课程ID`,
    c.`课程名称`,
    c.`学分`,
    ts.`星期`,
    CONCAT(ts.`开始时间`, '-', ts.`结束时间`) AS `上课时间`,
    CONCAT(r.`教学楼`, ' ', r.`房间号`) AS `上课地点`,
    teacher.`姓名` AS `授课教师`,
    CONCAT('第', t.`起始周`, '-', t.`结束周`, '周') AS `周次范围`,
    t.`单双周`
FROM `选课记录表` sc
JOIN `用户信息表` u ON sc.`学生ID` = u.`用户ID`
JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
JOIN `上课时间表` t ON oi.`开课实例ID` = t.`开课实例ID`
JOIN `时间段信息表` ts ON t.`时间段ID` = ts.`时间段ID`
LEFT JOIN `用户信息表` teacher ON t.`教师ID` = teacher.`用户ID`
WHERE u.`学号_工号` = '2021001'  -- 查询学号为2021001的学生(张三)
ORDER BY ts.`星期`, ts.`开始时间`, t.`起始周`;

-- 2.3 查询教师的授课情况(含课程、学生人数)
SELECT 
    u.`工号` AS `教师工号`,
    u.`姓名` AS `教师姓名`,
    d.`院系名称`,
    c.`课程ID`,
    c.`课程名称`,
    c.`学分`,
    ts.`星期`,
    CONCAT(ts.`开始时间`, '-', ts.`结束时间`) AS `上课时间`,
    CONCAT(r.`教学楼`, ' ', r.`房间号`) AS `上课地点`,
    CONCAT('第', t.`起始周`, '-', t.`结束周`, '周 ', t.`单双周`) AS `周次安排`,
    (oi.`已选对内人数` + oi.`已选对外人数`) AS `选课人数`,
    (oi.`对内名额` + oi.`对外名额`) AS `总名额`
FROM `授课关系表` tr
JOIN `用户信息表` u ON tr.`教师ID` = u.`用户ID`
JOIN `院系信息表` d ON u.`院系ID` = d.`院系ID`
JOIN `开课实例表` oi ON tr.`开课实例ID` = oi.`开课实例ID`
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `上课时间表` t ON oi.`开课实例ID` = t.`开课实例ID`
JOIN `时间段信息表` ts ON t.`时间段ID` = ts.`时间段ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
WHERE t.`教师ID` = u.`用户ID`  -- 只显示该教师负责的时间段
ORDER BY u.`姓名`, ts.`星期`, ts.`开始时间`;

-- 2.4 查询教室使用情况(按星期分组)
SELECT 
    CONCAT(r.`教学楼`, ' ', r.`房间号`) AS `教室`,
    r.`容量`,
    ts.`星期`,
    COUNT(DISTINCT t.`上课时间ID`) AS `使用次数`,
    GROUP_CONCAT(DISTINCT c.`课程名称` ORDER BY c.`课程名称` SEPARATOR ', ') AS `授课课程`
FROM `教室信息表` r
LEFT JOIN `开课实例表` oi ON r.`教室ID` = oi.`教室ID`
LEFT JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
LEFT JOIN `上课时间表` t ON oi.`开课实例ID` = t.`开课实例ID`
LEFT JOIN `时间段信息表` ts ON t.`时间段ID` = ts.`时间段ID`
GROUP BY r.`教室ID`, ts.`星期`
ORDER BY r.`教学楼`, r.`房间号`, ts.`星期`;


-- ==================== 子查询示例 ====================

-- 2.5 查询选课人数最多的课程
SELECT 
    c.`课程ID`,
    c.`课程名称`,
    (oi.`已选对内人数` + oi.`已选对外人数`) AS `选课人数`
FROM `开课实例表` oi
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
WHERE (oi.`已选对内人数` + oi.`已选对外人数`) = (
    SELECT MAX(oi2.`已选对内人数` + oi2.`已选对外人数`)
    FROM `开课实例表` oi2
);

-- 2.6 查询未选任何课程的学生
SELECT `用户ID`, `学号_工号`, `姓名`, d.`院系名称`
FROM `用户信息表` u
JOIN `院系信息表` d ON u.`院系ID` = d.`院系ID`
WHERE u.`角色` = '学生'
  AND u.`用户ID` NOT IN (
      SELECT DISTINCT `学生ID` 
      FROM `选课记录表`
  );

-- 2.7 查询选课人数超过平均值的课程
SELECT 
    c.`课程ID`,
    c.`课程名称`,
    (oi.`已选对内人数` + oi.`已选对外人数`) AS `选课人数`,
    ROUND(
        (SELECT AVG(oi2.`已选对内人数` + oi2.`已选对外人数`) 
         FROM `开课实例表` oi2), 
        2
    ) AS `平均选课人数`
FROM `开课实例表` oi
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
WHERE (oi.`已选对内人数` + oi.`已选对外人数`) > (
    SELECT AVG(oi2.`已选对内人数` + oi2.`已选对外人数`)
    FROM `开课实例表` oi2
)
ORDER BY `选课人数` DESC;

-- 2.8 查询授课门数最多的教师
SELECT 
    u.`姓名` AS `教师姓名`,
    d.`院系名称`,
    COUNT(DISTINCT tr.`开课实例ID`) AS `授课门数`
FROM `授课关系表` tr
JOIN `用户信息表` u ON tr.`教师ID` = u.`用户ID`
JOIN `院系信息表` d ON u.`院系ID` = d.`院系ID`
GROUP BY tr.`教师ID`
HAVING COUNT(DISTINCT tr.`开课实例ID`) = (
    SELECT MAX(课程数)
    FROM (
        SELECT COUNT(DISTINCT `开课实例ID`) AS 课程数
        FROM `授课关系表`
        GROUP BY `教师ID`
    ) AS temp
);

-- 2.9 查询每个院系选课最多的学生
SELECT 
    d.`院系名称`,
    u.`学号_工号`,
    u.`姓名`,
    COUNT(*) AS `选课门数`
FROM `选课记录表` sc
JOIN `用户信息表` u ON sc.`学生ID` = u.`用户ID`
JOIN `院系信息表` d ON u.`院系ID` = d.`院系ID`
GROUP BY u.`用户ID`
HAVING COUNT(*) >= ALL (
    SELECT COUNT(*)
    FROM `选课记录表` sc2
    JOIN `用户信息表` u2 ON sc2.`学生ID` = u2.`用户ID`
    WHERE u2.`院系ID` = u.`院系ID`
    GROUP BY sc2.`学生ID`
)
ORDER BY d.`院系名称`;


-- ==================== 聚合统计查询 ====================

-- 2.10 统计各院系的课程数量
SELECT 
    d.`院系名称`,
    COUNT(c.`课程ID`) AS `课程总数`,
    SUM(c.`学分`) AS `总学分`
FROM `院系信息表` d
LEFT JOIN `课程信息表` c ON d.`院系ID` = c.`院系ID`
GROUP BY d.`院系ID`
ORDER BY `课程总数` DESC;

-- 2.11 统计各课程的选课情况
SELECT 
    c.`课程ID`,
    c.`课程名称`,
    c.`学分`,
    d.`院系名称`,
    COUNT(sc.`学生ID`) AS `选课人数`,
    oi.`对内名额` + oi.`对外名额` AS `总名额`,
    CONCAT(
        ROUND(
            COUNT(sc.`学生ID`) * 100.0 / (oi.`对内名额` + oi.`对外名额`), 
            2
        ), 
        '%'
    ) AS `选课率`
FROM `课程信息表` c
JOIN `院系信息表` d ON c.`院系ID` = d.`院系ID`
JOIN `开课实例表` oi ON c.`课程ID` = oi.`课程ID`
LEFT JOIN `选课记录表` sc ON oi.`开课实例ID` = sc.`开课实例ID`
GROUP BY c.`课程ID`, oi.`开课实例ID`
ORDER BY `选课率` DESC;

-- 2.12 统计学生选课学分
SELECT 
    u.`学号_工号`,
    u.`姓名`,
    d.`院系名称`,
    COUNT(DISTINCT sc.`开课实例ID`) AS `选课门数`,
    SUM(c.`学分`) AS `总学分`
FROM `用户信息表` u
JOIN `院系信息表` d ON u.`院系ID` = d.`院系ID`
LEFT JOIN `选课记录表` sc ON u.`用户ID` = sc.`学生ID`
LEFT JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
LEFT JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
WHERE u.`角色` = '学生'
GROUP BY u.`用户ID`
ORDER BY `总学分` DESC;

-- 2.13 统计教师工作量(授课门数和学生人数)
SELECT 
    u.`姓名` AS `教师姓名`,
    d.`院系名称`,
    COUNT(DISTINCT tr.`开课实例ID`) AS `授课门数`,
    SUM(oi.`已选对内人数` + oi.`已选对外人数`) AS `学生总人数`,
    ROUND(
        SUM(oi.`已选对内人数` + oi.`已选对外人数`) * 1.0 / 
        COUNT(DISTINCT tr.`开课实例ID`), 
        2
    ) AS `平均每门课学生数`
FROM `授课关系表` tr
JOIN `用户信息表` u ON tr.`教师ID` = u.`用户ID`
JOIN `院系信息表` d ON u.`院系ID` = d.`院系ID`
JOIN `开课实例表` oi ON tr.`开课实例ID` = oi.`开课实例ID`
GROUP BY tr.`教师ID`
ORDER BY `授课门数` DESC, `学生总人数` DESC;

-- 2.14 统计教室使用率
SELECT 
    CONCAT(r.`教学楼`, ' ', r.`房间号`) AS `教室`,
    r.`容量`,
    COUNT(DISTINCT t.`上课时间ID`) AS `使用时间段数`,
    ROUND(
        COUNT(DISTINCT t.`上课时间ID`) * 100.0 / 
        (SELECT COUNT(*) FROM `时间段信息表`), 
        2
    ) AS `使用率(%)`
FROM `教室信息表` r
LEFT JOIN `开课实例表` oi ON r.`教室ID` = oi.`教室ID`
LEFT JOIN `上课时间表` t ON oi.`开课实例ID` = t.`开课实例ID`
GROUP BY r.`教室ID`
ORDER BY `使用率(%)` DESC;

-- 2.15 统计跨院系选课情况
SELECT 
    d1.`院系名称` AS `学生院系`,
    d2.`院系名称` AS `课程院系`,
    COUNT(*) AS `跨院系选课人次`
FROM `选课记录表` sc
JOIN `用户信息表` u ON sc.`学生ID` = u.`用户ID`
JOIN `院系信息表` d1 ON u.`院系ID` = d1.`院系ID`
JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `院系信息表` d2 ON c.`院系ID` = d2.`院系ID`
WHERE u.`院系ID` != c.`院系ID`
GROUP BY u.`院系ID`, c.`院系ID`
ORDER BY `跨院系选课人次` DESC;


-- 3. 视图使用示例

-- 3.1 使用视图查询当前学期的开课情况
SELECT * FROM `当前学期开课视图`
ORDER BY `课程ID`;

-- 3.2 使用视图查询学生课表
SELECT * FROM `学生课表视图`
WHERE `学号` = '2021001'  -- 张三的学号
ORDER BY `星期`, `开始时间`;

-- 3.3 使用视图查询教师课表
SELECT * FROM `教师课表视图`
WHERE `教师姓名` = '张教授'  -- 使用实际存在的教师名
ORDER BY `星期`, `开始时间`;

-- 3.4 使用视图统计各课程选课率
SELECT 
    `课程名称`,
    `已选人数`,
    `总名额`,
    CONCAT(ROUND(`已选人数` * 100.0 / `总名额`, 2), '%') AS `选课率`
FROM `当前学期开课视图`
WHERE `总名额` > 0
ORDER BY `已选人数` * 1.0 / `总名额` DESC;


-- 4. 实用业务查询

-- 4.1 查询有剩余名额的课程(可选课程列表)
SELECT 
    c.`课程ID`,
    c.`课程名称`,
    c.`学分`,
    d.`院系名称` AS `开课院系`,
    CONCAT(r.`教学楼`, ' ', r.`房间号`) AS `上课地点`,
    (oi.`对内名额` - oi.`已选对内人数`) AS `本院剩余名额`,
    (oi.`对外名额` - oi.`已选对外人数`) AS `跨院剩余名额`
FROM `开课实例表` oi
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `院系信息表` d ON c.`院系ID` = d.`院系ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`
WHERE s.`是否当前学期` = TRUE
  AND (
      oi.`已选对内人数` < oi.`对内名额` 
      OR oi.`已选对外人数` < oi.`对外名额`
  )
ORDER BY c.`课程ID`;

-- 4.2 查询某学生的选课历史
SELECT 
    s.`学年`,
    s.`学期类型`,
    c.`课程ID`,
    c.`课程名称`,
    c.`学分`,
    d.`院系名称` AS `开课院系`,
    sc.`选课时间`
FROM `选课记录表` sc
JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `院系信息表` d ON c.`院系ID` = d.`院系ID`
JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`
WHERE sc.`学生ID` = 16  -- 学生ID=16 (张三)
ORDER BY s.`学年` DESC, s.`学期类型`, c.`课程ID`;

-- 4.3 查询周三有课的所有课程(按时间排序)
SELECT 
    c.`课程ID`,
    c.`课程名称`,
    ts.`开始时间`,
    ts.`结束时间`,
    CONCAT(r.`教学楼`, ' ', r.`房间号`) AS `上课地点`,
    CONCAT('第', t.`起始周`, '-', t.`结束周`, '周 ', t.`单双周`) AS `周次安排`,
    u.`姓名` AS `授课教师`
FROM `上课时间表` t
JOIN `开课实例表` oi ON t.`开课实例ID` = oi.`开课实例ID`
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `时间段信息表` ts ON t.`时间段ID` = ts.`时间段ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
LEFT JOIN `用户信息表` u ON t.`教师ID` = u.`用户ID`
WHERE ts.`星期` = '星期三'
ORDER BY ts.`开始时间`, t.`起始周`;

-- 4.4 查询某教室的周课表
SELECT 
    ts.`星期`,
    ts.`开始时间`,
    ts.`结束时间`,
    c.`课程名称`,
    u.`姓名` AS `授课教师`,
    CONCAT('第', t.`起始周`, '-', t.`结束周`, '周 ', t.`单双周`) AS `周次安排`,
    (oi.`已选对内人数` + oi.`已选对外人数`) AS `选课人数`
FROM `上课时间表` t
JOIN `开课实例表` oi ON t.`开课实例ID` = oi.`开课实例ID`
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `时间段信息表` ts ON t.`时间段ID` = ts.`时间段ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
LEFT JOIN `用户信息表` u ON t.`教师ID` = u.`用户ID`
WHERE r.`教学楼` = '教学楼A' AND r.`房间号` = '101'  -- 使用实际存在的教室
ORDER BY ts.`星期`, ts.`开始时间`;

-- 4.5 查询即将满员的课程(选课率>90%)
SELECT 
    c.`课程ID`,
    c.`课程名称`,
    d.`院系名称`,
    (oi.`已选对内人数` + oi.`已选对外人数`) AS `已选人数`,
    (oi.`对内名额` + oi.`对外名额`) AS `总名额`,
    CONCAT(
        ROUND(
            (oi.`已选对内人数` + oi.`已选对外人数`) * 100.0 / 
            (oi.`对内名额` + oi.`对外名额`), 
            2
        ), 
        '%'
    ) AS `选课率`
FROM `开课实例表` oi
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `院系信息表` d ON c.`院系ID` = d.`院系ID`
JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`
WHERE s.`是否当前学期` = TRUE
  AND (oi.`已选对内人数` + oi.`已选对外人数`) * 100.0 / 
      (oi.`对内名额` + oi.`对外名额`) > 90
ORDER BY `选课率` DESC;

-- 4.6 查询某周某节有冲突风险的教室安排
SELECT 
    ts.`星期`,
    ts.`开始时间`,
    ts.`结束时间`,
    CONCAT(r.`教学楼`, ' ', r.`房间号`) AS `教室`,
    COUNT(*) AS `同时段课程数`,
    GROUP_CONCAT(c.`课程名称` SEPARATOR ', ') AS `课程列表`,
    GROUP_CONCAT(
        CONCAT('第', t.`起始周`, '-', t.`结束周`, '周 ', t.`单双周`) 
        SEPARATOR ' | '
    ) AS `周次安排`
FROM `上课时间表` t
JOIN `开课实例表` oi ON t.`开课实例ID` = oi.`开课实例ID`
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
JOIN `时间段信息表` ts ON t.`时间段ID` = ts.`时间段ID`
GROUP BY r.`教室ID`, t.`时间段ID`
HAVING COUNT(*) > 1  -- 同一教室同一时间有多门课
ORDER BY ts.`星期`, ts.`开始时间`;

-- 4.7 查询单双周排课情况统计
SELECT 
    t.`单双周`,
    COUNT(DISTINCT t.`上课时间ID`) AS `排课次数`,
    COUNT(DISTINCT t.`开课实例ID`) AS `课程数`,
    COUNT(DISTINCT t.`教师ID`) AS `教师数`
FROM `上课时间表` t
GROUP BY t.`单双周`
ORDER BY t.`单双周`;

-- 4.8 查询某学生可以选择的课程(排除已选和时间冲突)
SELECT DISTINCT
    c.`课程ID`,
    c.`课程名称`,
    c.`学分`,
    d.`院系名称`,
    CONCAT(r.`教学楼`, ' ', r.`房间号`) AS `上课地点`,
    CASE 
        WHEN c.`院系ID` = (SELECT `院系ID` FROM `用户信息表` WHERE `用户ID` = 16)
        THEN CONCAT('本院剩余: ', oi.`对内名额` - oi.`已选对内人数`)
        ELSE CONCAT('跨院剩余: ', oi.`对外名额` - oi.`已选对外人数`)
    END AS `剩余名额`
FROM `开课实例表` oi
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `院系信息表` d ON c.`院系ID` = d.`院系ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`
WHERE s.`是否当前学期` = TRUE
  -- 未选过该课程
  AND NOT EXISTS (
      SELECT 1 FROM `选课记录表` 
      WHERE `学生ID` = 16 AND `开课实例ID` = oi.`开课实例ID`
  )
  -- 有剩余名额
  AND (
      (c.`院系ID` = (SELECT `院系ID` FROM `用户信息表` WHERE `用户ID` = 16) 
       AND oi.`已选对内人数` < oi.`对内名额`)
      OR
      (c.`院系ID` != (SELECT `院系ID` FROM `用户信息表` WHERE `用户ID` = 16) 
       AND oi.`已选对外人数` < oi.`对外名额`)
  )
  -- 无时间冲突(简化版,实际应在应用层或存储过程中详细检查)
ORDER BY c.`课程ID`;


-- 5. 高级分析查询

-- 5.1 课程热度排行榜
SELECT 
    c.`课程ID`,
    c.`课程名称`,
    d.`院系名称`,
    (oi.`已选对内人数` + oi.`已选对外人数`) AS `选课人数`,
    (oi.`对内名额` + oi.`对外名额`) AS `总名额`,
    CONCAT(
        ROUND(
            (oi.`已选对内人数` + oi.`已选对外人数`) * 100.0 / 
            (oi.`对内名额` + oi.`对外名额`), 
            2
        ), 
        '%'
    ) AS `选课率`,
    CASE
        WHEN (oi.`已选对内人数` + oi.`已选对外人数`) * 100.0 / 
             (oi.`对内名额` + oi.`对外名额`) >= 90 THEN '爆满'
        WHEN (oi.`已选对内人数` + oi.`已选对外人数`) * 100.0 / 
             (oi.`对内名额` + oi.`对外名额`) >= 70 THEN '热门'
        WHEN (oi.`已选对内人数` + oi.`已选对外人数`) * 100.0 / 
             (oi.`对内名额` + oi.`对外名额`) >= 40 THEN '正常'
        ELSE '冷门'
    END AS `热度等级`
FROM `开课实例表` oi
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `院系信息表` d ON c.`院系ID` = d.`院系ID`
ORDER BY `选课人数` DESC;

-- 5.2 各时间段的课程分布
SELECT 
    ts.`星期`,
    ts.`开始时间`,
    ts.`结束时间`,
    COUNT(DISTINCT t.`开课实例ID`) AS `课程数量`,
    SUM(oi.`已选对内人数` + oi.`已选对外人数`) AS `学生总人次`
FROM `时间段信息表` ts
LEFT JOIN `上课时间表` t ON ts.`时间段ID` = t.`时间段ID`
LEFT JOIN `开课实例表` oi ON t.`开课实例ID` = oi.`开课实例ID`
GROUP BY ts.`时间段ID`
ORDER BY ts.`星期`, ts.`开始时间`;

-- 5.3 院系间的课程交流矩阵
SELECT 
    d1.`院系名称` AS `开课院系`,
    SUM(CASE WHEN d2.`院系名称` = d1.`院系名称` THEN 1 ELSE 0 END) AS `本院学生`,
    SUM(CASE WHEN d2.`院系名称` != d1.`院系名称` THEN 1 ELSE 0 END) AS `外院学生`,
    COUNT(*) AS `总选课人次`
FROM `选课记录表` sc
JOIN `用户信息表` u ON sc.`学生ID` = u.`用户ID`
JOIN `院系信息表` d2 ON u.`院系ID` = d2.`院系ID`
JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `院系信息表` d1 ON c.`院系ID` = d1.`院系ID`
GROUP BY d1.`院系ID`
ORDER BY d1.`院系名称`;

-- 5.4 学生选课行为分析
SELECT 
    CASE
        WHEN `选课门数` = 0 THEN '未选课'
        WHEN `选课门数` BETWEEN 1 AND 3 THEN '选课较少(1-3门)'
        WHEN `选课门数` BETWEEN 4 AND 6 THEN '选课正常(4-6门)'
        WHEN `选课门数` BETWEEN 7 AND 9 THEN '选课较多(7-9门)'
        ELSE '选课很多(10门以上)'
    END AS `选课类型`,
    COUNT(*) AS `学生人数`,
    ROUND(AVG(`选课门数`), 2) AS `平均选课门数`,
    ROUND(AVG(`总学分`), 2) AS `平均学分`
FROM (
    SELECT 
        u.`用户ID`,
        COUNT(sc.`开课实例ID`) AS `选课门数`,
        COALESCE(SUM(c.`学分`), 0) AS `总学分`
    FROM `用户信息表` u
    LEFT JOIN `选课记录表` sc ON u.`用户ID` = sc.`学生ID`
    LEFT JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
    LEFT JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
    WHERE u.`角色` = '学生'
    GROUP BY u.`用户ID`
) AS student_stats
GROUP BY `选课类型`
ORDER BY `平均选课门数`;