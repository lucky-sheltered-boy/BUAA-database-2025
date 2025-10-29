-- 建表脚本

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 基础实体表

-- 院系信息表
DROP TABLE IF EXISTS `院系信息表`;
CREATE TABLE `院系信息表` (
  `院系ID` INT(11) NOT NULL AUTO_INCREMENT,
  `院系名称` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`院系ID`),
  UNIQUE KEY `uk_院系名称` (`院系名称`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 教室信息表
DROP TABLE IF EXISTS `教室信息表`;
CREATE TABLE `教室信息表` (
  `教室ID` INT(11) NOT NULL AUTO_INCREMENT,
  `教学楼` VARCHAR(50) NOT NULL,
  `房间号` VARCHAR(20) NOT NULL,
  `容量` INT(11) NOT NULL,
  PRIMARY KEY (`教室ID`),
  UNIQUE KEY `uk_教学楼_房间号` (`教学楼`, `房间号`),
  CHECK (`容量` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 时间段信息表（定义上课的基本时间单元）
DROP TABLE IF EXISTS `时间段信息表`;
CREATE TABLE `时间段信息表` (
  `时间段ID` INT(11) NOT NULL AUTO_INCREMENT,
  `星期` ENUM('星期一','星期二','星期三','星期四','星期五','星期六','星期日') NOT NULL,
  `开始时间` TIME NOT NULL,
  `结束时间` TIME NOT NULL,
  PRIMARY KEY (`时间段ID`),
  UNIQUE KEY `uk_时间段` (`星期`, `开始时间`, `结束时间`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 学期信息表（管理学期及选课时间窗口）
DROP TABLE IF EXISTS `学期信息表`;
CREATE TABLE `学期信息表` (
  `学期ID` INT(11) NOT NULL AUTO_INCREMENT,
  `学年` VARCHAR(10) NOT NULL,
  `学期类型` ENUM('春季','秋季') NOT NULL,
  `开始日期` DATE NOT NULL,
  `结束日期` DATE NOT NULL,
  `选课开始时间` DATETIME DEFAULT NULL,
  `选课结束时间` DATETIME DEFAULT NULL,
  `是否当前学期` BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (`学期ID`),
  KEY `idx_当前学期` (`是否当前学期`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 课程信息表
DROP TABLE IF EXISTS `课程信息表`;
CREATE TABLE `课程信息表` (
  `课程ID` VARCHAR(20) NOT NULL,
  `课程名称` VARCHAR(100) NOT NULL,
  `学分` DECIMAL(3,1) NOT NULL,
  `院系ID` INT(11) NOT NULL,
  PRIMARY KEY (`课程ID`),
  KEY `idx_院系` (`院系ID`),
  CONSTRAINT `fk_课程_院系` FOREIGN KEY (`院系ID`) REFERENCES `院系信息表` (`院系ID`),
  CHECK (`学分` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 用户信息表（统一管理学生、教师、教务）
DROP TABLE IF EXISTS `用户信息表`;
CREATE TABLE `用户信息表` (
  `用户ID` INT(11) NOT NULL AUTO_INCREMENT,
  `学号_工号` VARCHAR(20) NOT NULL,
  `姓名` VARCHAR(50) NOT NULL,
  `密码哈希` VARCHAR(255) NOT NULL,
  `角色` ENUM('学生','教师','教务') NOT NULL,
  `院系ID` INT(11) NOT NULL,
  PRIMARY KEY (`用户ID`),
  UNIQUE KEY `uk_学号_工号` (`学号_工号`),
  KEY `idx_角色` (`角色`),
  KEY `idx_院系` (`院系ID`),
  CONSTRAINT `fk_用户_院系` FOREIGN KEY (`院系ID`) REFERENCES `院系信息表` (`院系ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 核心表

-- 开课实例表（记录课程在特定学期的具体安排）
DROP TABLE IF EXISTS `开课实例表`;
CREATE TABLE `开课实例表` (
  `开课实例ID` INT(11) NOT NULL AUTO_INCREMENT,
  `课程ID` VARCHAR(20) NOT NULL,
  `教室ID` INT(11) NOT NULL,
  `学期ID` INT(11) NOT NULL,
  `对内名额` INT(11) NOT NULL,
  `对外名额` INT(11) NOT NULL,
  `已选对内人数` INT(11) NOT NULL DEFAULT 0,
  `已选对外人数` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`开课实例ID`),
  KEY `idx_课程` (`课程ID`),
  KEY `idx_教室` (`教室ID`),
  KEY `idx_学期` (`学期ID`),
  KEY `idx_学期_课程` (`学期ID`, `课程ID`),
  CONSTRAINT `fk_开课_课程` FOREIGN KEY (`课程ID`) REFERENCES `课程信息表` (`课程ID`),
  CONSTRAINT `fk_开课_教室` FOREIGN KEY (`教室ID`) REFERENCES `教室信息表` (`教室ID`),
  CONSTRAINT `fk_开课_学期` FOREIGN KEY (`学期ID`) REFERENCES `学期信息表` (`学期ID`),
  CHECK (`对内名额` > 0),
  CHECK (`对外名额` >= 0),
  CHECK (`已选对内人数` >= 0),
  CHECK (`已选对内人数` <= `对内名额`),
  CHECK (`已选对外人数` >= 0),
  CHECK (`已选对外人数` <= `对外名额`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 联系表

-- 授课关系表（教师 M:N 开课实例，支持多教师授课）
DROP TABLE IF EXISTS `授课关系表`;
CREATE TABLE `授课关系表` (
  `教师ID` INT(11) NOT NULL,
  `开课实例ID` INT(11) NOT NULL,
  PRIMARY KEY (`教师ID`, `开课实例ID`),
  KEY `idx_开课实例` (`开课实例ID`),
  CONSTRAINT `fk_授课_教师` FOREIGN KEY (`教师ID`) REFERENCES `用户信息表` (`用户ID`),
  CONSTRAINT `fk_授课_开课实例` FOREIGN KEY (`开课实例ID`) REFERENCES `开课实例表` (`开课实例ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 选课记录表（学生 M:N 开课实例）
DROP TABLE IF EXISTS `选课记录表`;
CREATE TABLE `选课记录表` (
  `学生ID` INT(11) NOT NULL,
  `开课实例ID` INT(11) NOT NULL,
  `选课时间` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`学生ID`, `开课实例ID`),
  KEY `idx_开课实例` (`开课实例ID`),
  KEY `idx_选课时间` (`选课时间`),
  CONSTRAINT `fk_选课_学生` FOREIGN KEY (`学生ID`) REFERENCES `用户信息表` (`用户ID`),
  CONSTRAINT `fk_选课_开课实例` FOREIGN KEY (`开课实例ID`) REFERENCES `开课实例表` (`开课实例ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 上课时间表（开课实例 M:N 时间段，支持周次范围和单双周设置）
DROP TABLE IF EXISTS `上课时间表`;
CREATE TABLE `上课时间表` (
  `上课时间ID` INT(11) NOT NULL AUTO_INCREMENT,
  `开课实例ID` INT(11) NOT NULL,
  `时间段ID` INT(11) NOT NULL,
  `教师ID` INT(11) DEFAULT NULL,
  `起始周` INT(11) NOT NULL DEFAULT 1,
  `结束周` INT(11) NOT NULL DEFAULT 16,
  `单双周` ENUM('全部','单周','双周') NOT NULL DEFAULT '全部',
  PRIMARY KEY (`上课时间ID`),
  UNIQUE KEY `uk_开课实例_时间段_周次` (`开课实例ID`, `时间段ID`, `起始周`, `结束周`, `单双周`),
  KEY `idx_时间段` (`时间段ID`),
  KEY `idx_教师` (`教师ID`),
  KEY `idx_周次范围` (`起始周`, `结束周`),
  CONSTRAINT `fk_上课时间_开课实例` FOREIGN KEY (`开课实例ID`) REFERENCES `开课实例表` (`开课实例ID`) ON DELETE CASCADE,
  CONSTRAINT `fk_上课时间_时间段` FOREIGN KEY (`时间段ID`) REFERENCES `时间段信息表` (`时间段ID`),
  CONSTRAINT `fk_上课时间_教师` FOREIGN KEY (`教师ID`) REFERENCES `用户信息表` (`用户ID`),
  CHECK (`起始周` >= 1 AND `起始周` <= 20),
  CHECK (`结束周` >= 1 AND `结束周` <= 20),
  CHECK (`结束周` >= `起始周`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='记录开课实例的上课时间安排,支持分周次、单双周等灵活排课';

-- 视图

-- 视图1: 当前学期开课实例视图（自动筛选当前学期并计算剩余名额）
DROP VIEW IF EXISTS `当前学期开课实例视图`;
CREATE VIEW `当前学期开课实例视图` AS
SELECT 
    oi.`开课实例ID`,
    oi.`课程ID`,
    c.`课程名称`,
    c.`学分`,
    oi.`教室ID`,
    r.`教学楼`,
    r.`房间号`,
    oi.`学期ID`,
    s.`学年`,
    s.`学期类型`,
    oi.`对内名额`,
    oi.`对外名额`,
    oi.`已选对内人数`,
    oi.`已选对外人数`,
    (oi.`对内名额` - oi.`已选对内人数`) AS `对内剩余名额`,
    (oi.`对外名额` - oi.`已选对外人数`) AS `对外剩余名额`
FROM `开课实例表` oi
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`
WHERE s.`是否当前学期` = TRUE;

-- 视图2: 学生选课详情视图（展示学生选课的完整信息）
DROP VIEW IF EXISTS `学生选课详情视图`;
CREATE VIEW `学生选课详情视图` AS
SELECT 
    sc.`学生ID`,
    u.`学号_工号` AS `学号`,
    u.`姓名` AS `学生姓名`,
    oi.`开课实例ID`,
    c.`课程ID`,
    c.`课程名称`,
    c.`学分`,
    s.`学年`,
    s.`学期类型`,
    r.`教学楼`,
    r.`房间号`,
    sc.`选课时间`
FROM `选课记录表` sc
JOIN `用户信息表` u ON sc.`学生ID` = u.`用户ID`
JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`;

-- 视图3: 教师授课详情视图（展示教师授课的完整信息）
DROP VIEW IF EXISTS `教师授课详情视图`;
CREATE VIEW `教师授课详情视图` AS
SELECT 
    tr.`教师ID`,
    u.`学号_工号` AS `工号`,
    u.`姓名` AS `教师姓名`,
    oi.`开课实例ID`,
    c.`课程ID`,
    c.`课程名称`,
    c.`学分`,
    s.`学年`,
    s.`学期类型`,
    r.`教学楼`,
    r.`房间号`,
    oi.`对内名额` + oi.`对外名额` AS `总容量`,
    oi.`已选对内人数` + oi.`已选对外人数` AS `已选人数`
FROM `授课关系表` tr
JOIN `用户信息表` u ON tr.`教师ID` = u.`用户ID`
JOIN `开课实例表` oi ON tr.`开课实例ID` = oi.`开课实例ID`
JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`;

SET FOREIGN_KEY_CHECKS = 1;