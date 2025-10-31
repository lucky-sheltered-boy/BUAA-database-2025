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



-- 触发器脚本

SET NAMES utf8mb4;

-- 1. 选课相关触发器

-- 触发器1: 选课前检查 - 检查名额、时间冲突、选课时间窗口
DROP TRIGGER IF EXISTS `trg_before_enroll_check`;
DELIMITER $$
CREATE TRIGGER `trg_before_enroll_check`
BEFORE INSERT ON `选课记录表`
FOR EACH ROW
BEGIN
    DECLARE v_课程ID VARCHAR(20);
    DECLARE v_院系ID INT;
    DECLARE v_学生院系ID INT;
    DECLARE v_学期ID INT;
    DECLARE v_对内名额 INT;
    DECLARE v_对外名额 INT;
    DECLARE v_已选对内人数 INT;
    DECLARE v_已选对外人数 INT;
    DECLARE v_选课开始时间 DATETIME;
    DECLARE v_选课结束时间 DATETIME;
    DECLARE v_是否本院系 BOOLEAN;
    DECLARE v_冲突数 INT;
    
    -- 获取开课实例信息
    SELECT oi.`课程ID`, c.`院系ID`, oi.`学期ID`,
           oi.`对内名额`, oi.`对外名额`, 
           oi.`已选对内人数`, oi.`已选对外人数`
    INTO v_课程ID, v_院系ID, v_学期ID,
         v_对内名额, v_对外名额,
         v_已选对内人数, v_已选对外人数
    FROM `开课实例表` oi
    JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
    WHERE oi.`开课实例ID` = NEW.`开课实例ID`;
    
    -- 验证开课实例是否存在
    IF v_院系ID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '选课失败: 开课实例不存在或课程信息不完整';
    END IF;
    
    -- 获取学生院系
    SELECT `院系ID` INTO v_学生院系ID
    FROM `用户信息表`
    WHERE `用户ID` = NEW.`学生ID` AND `角色` = '学生';
    
    -- 验证学生是否存在
    IF v_学生院系ID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '选课失败: 学生信息不存在或用户不是学生';
    END IF;
    
    -- 判断是否本院系学生
    SET v_是否本院系 = (v_学生院系ID = v_院系ID);
    
    -- 1. 检查名额是否已满
    IF v_是否本院系 THEN
        IF v_已选对内人数 >= v_对内名额 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '选课失败: 本院系名额已满';
        END IF;
    ELSE
        IF v_已选对外人数 >= v_对外名额 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '选课失败: 跨院系名额已满';
        END IF;
    END IF;
    
    -- 2. 检查选课时间窗口
    SELECT `选课开始时间`, `选课结束时间`
    INTO v_选课开始时间, v_选课结束时间
    FROM `学期信息表`
    WHERE `学期ID` = v_学期ID;
    
    IF v_选课开始时间 IS NOT NULL AND v_选课结束时间 IS NOT NULL THEN
        IF NEW.`选课时间` < v_选课开始时间 OR NEW.`选课时间` > v_选课结束时间 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '选课失败: 不在选课时间窗口内';
        END IF;
    END IF;
    
    -- 3. 检查重复选课 (必须在时间冲突检查之前)
    IF EXISTS (
        SELECT 1 FROM `选课记录表`
        WHERE `学生ID` = NEW.`学生ID` AND `开课实例ID` = NEW.`开课实例ID`
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '选课失败: 已选修该课程，不能重复选课';
    END IF;
    
    -- 4. 检查时间冲突(考虑周次，排除同一门课)
    SELECT COUNT(*) INTO v_冲突数
    FROM `选课记录表` sc
    JOIN `上课时间表` t1 ON sc.`开课实例ID` = t1.`开课实例ID`
    JOIN `上课时间表` t2 ON t2.`开课实例ID` = NEW.`开课实例ID`
    WHERE sc.`学生ID` = NEW.`学生ID`
      AND sc.`开课实例ID` != NEW.`开课实例ID`  -- 排除同一门课
      AND t1.`时间段ID` = t2.`时间段ID`
      -- 周次范围重叠检查
      AND t1.`起始周` <= t2.`结束周`
      AND t1.`结束周` >= t2.`起始周`
      -- 单双周冲突检查
      AND (
          t1.`单双周` = '全部' OR 
          t2.`单双周` = '全部' OR 
          t1.`单双周` = t2.`单双周`
      );
    
    IF v_冲突数 > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '选课失败: 上课时间冲突';
    END IF;
    
END$$
DELIMITER ;

-- 触发器2: 选课后更新已选人数
DROP TRIGGER IF EXISTS `trg_after_enroll_update_count`;
DELIMITER $$
CREATE TRIGGER `trg_after_enroll_update_count`
AFTER INSERT ON `选课记录表`
FOR EACH ROW
BEGIN
    DECLARE v_课程院系ID INT;
    DECLARE v_学生院系ID INT;
    
    -- 获取课程所属院系
    SELECT c.`院系ID` INTO v_课程院系ID
    FROM `开课实例表` oi
    JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
    WHERE oi.`开课实例ID` = NEW.`开课实例ID`;
    
    -- 获取学生所属院系
    SELECT `院系ID` INTO v_学生院系ID
    FROM `用户信息表`
    WHERE `用户ID` = NEW.`学生ID`;
    
    -- 根据是否本院系更新对应的已选人数
    IF v_学生院系ID = v_课程院系ID THEN
        UPDATE `开课实例表`
        SET `已选对内人数` = `已选对内人数` + 1
        WHERE `开课实例ID` = NEW.`开课实例ID`;
    ELSE
        UPDATE `开课实例表`
        SET `已选对外人数` = `已选对外人数` + 1
        WHERE `开课实例ID` = NEW.`开课实例ID`;
    END IF;
END$$
DELIMITER ;

-- 触发器3: 退课后更新已选人数
DROP TRIGGER IF EXISTS `trg_after_drop_update_count`;
DELIMITER $$
CREATE TRIGGER `trg_after_drop_update_count`
AFTER DELETE ON `选课记录表`
FOR EACH ROW
BEGIN
    DECLARE v_课程院系ID INT;
    DECLARE v_学生院系ID INT;
    
    -- 获取课程所属院系
    SELECT c.`院系ID` INTO v_课程院系ID
    FROM `开课实例表` oi
    JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
    WHERE oi.`开课实例ID` = OLD.`开课实例ID`;
    
    -- 获取学生所属院系
    SELECT `院系ID` INTO v_学生院系ID
    FROM `用户信息表`
    WHERE `用户ID` = OLD.`学生ID`;
    
    -- 根据是否本院系更新对应的已选人数
    IF v_学生院系ID = v_课程院系ID THEN
        UPDATE `开课实例表`
        SET `已选对内人数` = `已选对内人数` - 1
        WHERE `开课实例ID` = OLD.`开课实例ID`;
    ELSE
        UPDATE `开课实例表`
        SET `已选对外人数` = `已选对外人数` - 1
        WHERE `开课实例ID` = OLD.`开课实例ID`;
    END IF;
END$$
DELIMITER ;

-- 2. 排课相关触发器

-- 触发器4: 排课前检查教师冲突(考虑周次)
DROP TRIGGER IF EXISTS `trg_before_schedule_check_teacher`;
DELIMITER $$
CREATE TRIGGER `trg_before_schedule_check_teacher`
BEFORE INSERT ON `上课时间表`
FOR EACH ROW
BEGIN
    DECLARE v_冲突数 INT;
    
    -- 如果没有指定教师,跳过教师冲突检查
    IF NEW.`教师ID` IS NULL THEN
        SET v_冲突数 = 0;
    ELSE
        -- 检查教师时间冲突(同一时间段+周次重叠+单双周冲突)
        SELECT COUNT(*) INTO v_冲突数
        FROM `上课时间表` t
        WHERE t.`教师ID` = NEW.`教师ID`
          AND t.`时间段ID` = NEW.`时间段ID`
          -- 周次范围重叠
          AND t.`起始周` <= NEW.`结束周`
          AND t.`结束周` >= NEW.`起始周`
          -- 单双周冲突
          AND (
              t.`单双周` = '全部' OR 
              NEW.`单双周` = '全部' OR 
              t.`单双周` = NEW.`单双周`
          )
          AND t.`开课实例ID` != NEW.`开课实例ID`;
        
        IF v_冲突数 > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '排课失败: 教师时间冲突';
        END IF;
    END IF;
END$$
DELIMITER ;

-- 触发器5: 排课前检查教室冲突(考虑周次)
DROP TRIGGER IF EXISTS `trg_before_schedule_check_room`;
DELIMITER $$
CREATE TRIGGER `trg_before_schedule_check_room`
BEFORE INSERT ON `上课时间表`
FOR EACH ROW
BEGIN
    DECLARE v_教室ID INT;
    DECLARE v_冲突数 INT;
    
    -- 获取当前开课实例的教室
    SELECT `教室ID` INTO v_教室ID
    FROM `开课实例表`
    WHERE `开课实例ID` = NEW.`开课实例ID`;
    
    -- 验证开课实例是否存在
    IF v_教室ID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '排课失败: 开课实例不存在';
    END IF;
    
    -- 检查教室时间冲突(同一时间段+同一教室+周次重叠+单双周冲突)
    SELECT COUNT(*) INTO v_冲突数
    FROM `上课时间表` t
    JOIN `开课实例表` oi ON t.`开课实例ID` = oi.`开课实例ID`
    WHERE oi.`教室ID` = v_教室ID
      AND t.`时间段ID` = NEW.`时间段ID`
      -- 周次范围重叠
      AND t.`起始周` <= NEW.`结束周`
      AND t.`结束周` >= NEW.`起始周`
      -- 单双周冲突
      AND (
          t.`单双周` = '全部' OR 
          NEW.`单双周` = '全部' OR 
          t.`单双周` = NEW.`单双周`
      )
      AND t.`开课实例ID` != NEW.`开课实例ID`;
    
    IF v_冲突数 > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '排课失败: 教室时间冲突';
    END IF;
END$$
DELIMITER ;

-- 触发器6: 更新排课时同样检查教师冲突
DROP TRIGGER IF EXISTS `trg_before_schedule_update_check_teacher`;
DELIMITER $$
CREATE TRIGGER `trg_before_schedule_update_check_teacher`
BEFORE UPDATE ON `上课时间表`
FOR EACH ROW
BEGIN
    DECLARE v_冲突数 INT;
    
    -- 如果没有指定教师,跳过教师冲突检查
    IF NEW.`教师ID` IS NULL THEN
        SET v_冲突数 = 0;
    ELSE
        -- 检查教师时间冲突(排除自己)
        SELECT COUNT(*) INTO v_冲突数
        FROM `上课时间表` t
        WHERE t.`教师ID` = NEW.`教师ID`
          AND t.`时间段ID` = NEW.`时间段ID`
          AND t.`起始周` <= NEW.`结束周`
          AND t.`结束周` >= NEW.`起始周`
          AND (
              t.`单双周` = '全部' OR 
              NEW.`单双周` = '全部' OR 
              t.`单双周` = NEW.`单双周`
          )
          AND t.`上课时间ID` != NEW.`上课时间ID`;
        
        IF v_冲突数 > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '排课更新失败: 教师时间冲突';
        END IF;
    END IF;
END$$
DELIMITER ;

-- 触发器7: 更新排课时同样检查教室冲突
DROP TRIGGER IF EXISTS `trg_before_schedule_update_check_room`;
DELIMITER $$
CREATE TRIGGER `trg_before_schedule_update_check_room`
BEFORE UPDATE ON `上课时间表`
FOR EACH ROW
BEGIN
    DECLARE v_教室ID INT;
    DECLARE v_冲突数 INT;
    
    -- 获取当前开课实例的教室
    SELECT `教室ID` INTO v_教室ID
    FROM `开课实例表`
    WHERE `开课实例ID` = NEW.`开课实例ID`;
    
    -- 验证开课实例是否存在
    IF v_教室ID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '排课更新失败: 开课实例不存在';
    END IF;
    
    -- 检查教室时间冲突(排除自己)
    SELECT COUNT(*) INTO v_冲突数
    FROM `上课时间表` t
    JOIN `开课实例表` oi ON t.`开课实例ID` = oi.`开课实例ID`
    WHERE oi.`教室ID` = v_教室ID
      AND t.`时间段ID` = NEW.`时间段ID`
      AND t.`起始周` <= NEW.`结束周`
      AND t.`结束周` >= NEW.`起始周`
      AND (
          t.`单双周` = '全部' OR 
          NEW.`单双周` = '全部' OR 
          t.`单双周` = NEW.`单双周`
      )
      AND t.`上课时间ID` != NEW.`上课时间ID`;
    
    IF v_冲突数 > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '排课更新失败: 教室时间冲突';
    END IF;
END$$
DELIMITER ;

-- 3. 数据一致性维护触发器

-- 触发器8: 防止修改已有选课记录的开课实例
DROP TRIGGER IF EXISTS `trg_before_enroll_update_prevent`;
DELIMITER $$
CREATE TRIGGER `trg_before_enroll_update_prevent`
BEFORE UPDATE ON `选课记录表`
FOR EACH ROW
BEGIN
    IF OLD.`开课实例ID` != NEW.`开课实例ID` OR OLD.`学生ID` != NEW.`学生ID` THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '不允许修改选课记录的学生或开课实例,请先退课再重新选课';
    END IF;
END$$
DELIMITER ;

-- 触发器9: 防止删除已有选课记录的开课实例
DROP TRIGGER IF EXISTS `trg_before_course_instance_delete_check`;
DELIMITER $$
CREATE TRIGGER `trg_before_course_instance_delete_check`
BEFORE DELETE ON `开课实例表`
FOR EACH ROW
BEGIN
    DECLARE v_选课人数 INT;
    
    SELECT COUNT(*) INTO v_选课人数
    FROM `选课记录表`
    WHERE `开课实例ID` = OLD.`开课实例ID`;
    
    IF v_选课人数 > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '无法删除开课实例: 已有学生选课';
    END IF;
END$$
DELIMITER ;

-- 触发器10: 检查教室容量是否足够
DROP TRIGGER IF EXISTS `trg_before_course_instance_check_capacity`;
DELIMITER $$
CREATE TRIGGER `trg_before_course_instance_check_capacity`
BEFORE INSERT ON `开课实例表`
FOR EACH ROW
BEGIN
    DECLARE v_教室容量 INT;
    DECLARE v_总名额 INT;
    
    -- 获取教室容量
    SELECT `容量` INTO v_教室容量
    FROM `教室信息表`
    WHERE `教室ID` = NEW.`教室ID`;
    
    -- 验证教室是否存在
    IF v_教室容量 IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '开课失败: 教室不存在';
    END IF;
    
    -- 计算总名额
    SET v_总名额 = NEW.`对内名额` + NEW.`对外名额`;
    
    -- 检查总名额是否超过教室容量
    IF v_总名额 > v_教室容量 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '开课失败: 总名额超过教室容量';
    END IF;
END$$
DELIMITER ;

-- 触发器11: 更新开课实例时检查教室容量
DROP TRIGGER IF EXISTS `trg_before_course_instance_update_check_capacity`;
DELIMITER $$
CREATE TRIGGER `trg_before_course_instance_update_check_capacity`
BEFORE UPDATE ON `开课实例表`
FOR EACH ROW
BEGIN
    DECLARE v_教室容量 INT;
    DECLARE v_总名额 INT;
    
    -- 获取教室容量(可能更换了教室)
    SELECT `容量` INTO v_教室容量
    FROM `教室信息表`
    WHERE `教室ID` = NEW.`教室ID`;
    
    -- 验证教室是否存在
    IF v_教室容量 IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '更新失败: 教室不存在';
    END IF;
    
    -- 计算总名额
    SET v_总名额 = NEW.`对内名额` + NEW.`对外名额`;
    
    -- 检查总名额是否超过教室容量
    IF v_总名额 > v_教室容量 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '更新失败: 总名额超过教室容量';
    END IF;
    
    -- 检查已选人数是否超过新名额
    IF NEW.`已选对内人数` > NEW.`对内名额` THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '更新失败: 已选对内人数超过新的对内名额';
    END IF;
    
    IF NEW.`已选对外人数` > NEW.`对外名额` THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '更新失败: 已选对外人数超过新的对外名额';
    END IF;
END$$
DELIMITER ;

-- 触发器创建完成

-- 查看所有触发器
SELECT 
    TRIGGER_NAME AS '触发器名称',
    EVENT_MANIPULATION AS '触发事件',
    EVENT_OBJECT_TABLE AS '作用表',
    ACTION_TIMING AS '触发时机',
    ACTION_STATEMENT AS '触发语句'
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
ORDER BY EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION;



-- 存储过程脚本

SET NAMES utf8mb4;

-- 1. 基础数据管理存储过程

-- 存储过程1: 添加院系
DROP PROCEDURE IF EXISTS `sp_add_department`;
DELIMITER $$
CREATE PROCEDURE `sp_add_department`(
    IN p_院系名称 VARCHAR(100),
    OUT p_院系ID INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_message = '❌ 添加院系失败: 数据库错误';
        SET p_院系ID = -1;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- 参数验证
    IF p_院系名称 IS NULL OR TRIM(p_院系名称) = '' THEN
        SET p_message = '❌ 添加失败: 院系名称不能为空';
        SET p_院系ID = -1;
        ROLLBACK;
    -- 检查院系名称是否已存在
    ELSEIF EXISTS (SELECT 1 FROM `院系信息表` WHERE `院系名称` = p_院系名称) THEN
        SET p_message = CONCAT('❌ 添加失败: 院系"', p_院系名称, '"已存在');
        SET p_院系ID = -1;
        ROLLBACK;
    ELSE
        INSERT INTO `院系信息表` (`院系名称`) VALUES (p_院系名称);
        SET p_院系ID = LAST_INSERT_ID();
        SET p_message = CONCAT('✅ 成功添加院系: ', p_院系名称, ' (ID: ', p_院系ID, ')');
        COMMIT;
    END IF;
END$$
DELIMITER ;

-- 存储过程2: 添加教室
DROP PROCEDURE IF EXISTS `sp_add_classroom`;
DELIMITER $$
CREATE PROCEDURE `sp_add_classroom`(
    IN p_教学楼 VARCHAR(50),
    IN p_房间号 VARCHAR(20),
    IN p_容量 INT,
    OUT p_教室ID INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_message = '❌ 添加教室失败: 数据库错误';
        SET p_教室ID = -1;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- 参数验证
    IF p_教学楼 IS NULL OR TRIM(p_教学楼) = '' THEN
        SET p_message = '❌ 添加失败: 教学楼名称不能为空';
        SET p_教室ID = -1;
        ROLLBACK;
    ELSEIF p_房间号 IS NULL OR TRIM(p_房间号) = '' THEN
        SET p_message = '❌ 添加失败: 房间号不能为空';
        SET p_教室ID = -1;
        ROLLBACK;
    -- 检查容量是否合法
    ELSEIF p_容量 IS NULL OR p_容量 <= 0 THEN
        SET p_message = CONCAT('❌ 添加失败: 教室容量必须大于0 (当前值: ', COALESCE(p_容量, 'NULL'), ')');
        SET p_教室ID = -1;
        ROLLBACK;
    ELSEIF p_容量 > 1000 THEN
        SET p_message = CONCAT('❌ 添加失败: 教室容量不能超过1000 (当前值: ', p_容量, ')');
        SET p_教室ID = -1;
        ROLLBACK;
    -- 检查教室是否已存在
    ELSEIF EXISTS (
        SELECT 1 FROM `教室信息表` 
        WHERE `教学楼` = p_教学楼 AND `房间号` = p_房间号
    ) THEN
        SET p_message = CONCAT('❌ 添加失败: 教室"', p_教学楼, ' ', p_房间号, '"已存在');
        SET p_教室ID = -1;
        ROLLBACK;
    ELSE
        INSERT INTO `教室信息表` (`教学楼`, `房间号`, `容量`) 
        VALUES (p_教学楼, p_房间号, p_容量);
        SET p_教室ID = LAST_INSERT_ID();
        SET p_message = CONCAT('✅ 成功添加教室: ', p_教学楼, ' ', p_房间号, ' (容量: ', p_容量, '人, ID: ', p_教室ID, ')');
        COMMIT;
    END IF;
END$$
DELIMITER ;

-- 存储过程3: 添加课程
DROP PROCEDURE IF EXISTS `sp_add_course`;
DELIMITER $$
CREATE PROCEDURE `sp_add_course`(
    IN p_课程ID VARCHAR(20),
    IN p_课程名称 VARCHAR(100),
    IN p_学分 DECIMAL(3,1),
    IN p_院系ID INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_院系名称 VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_message = '❌ 添加课程失败: 数据库错误';
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- 参数验证
    IF p_课程ID IS NULL OR TRIM(p_课程ID) = '' THEN
        SET p_message = '❌ 添加失败: 课程ID不能为空';
        ROLLBACK;
    ELSEIF p_课程名称 IS NULL OR TRIM(p_课程名称) = '' THEN
        SET p_message = '❌ 添加失败: 课程名称不能为空';
        ROLLBACK;
    -- 检查学分是否合法
    ELSEIF p_学分 IS NULL OR p_学分 <= 0 THEN
        SET p_message = CONCAT('❌ 添加失败: 学分必须大于0 (当前值: ', COALESCE(p_学分, 'NULL'), ')');
        ROLLBACK;
    ELSEIF p_学分 > 10 THEN
        SET p_message = CONCAT('❌ 添加失败: 学分不能超过10 (当前值: ', p_学分, ')');
        ROLLBACK;
    -- 检查院系是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `院系信息表` WHERE `院系ID` = p_院系ID) THEN
        SET p_message = CONCAT('❌ 添加失败: 院系ID ', p_院系ID, ' 不存在');
        ROLLBACK;
    -- 检查课程ID是否已存在
    ELSEIF EXISTS (SELECT 1 FROM `课程信息表` WHERE `课程ID` = p_课程ID) THEN
        SET p_message = CONCAT('❌ 添加失败: 课程ID "', p_课程ID, '" 已存在');
        ROLLBACK;
    ELSE
        -- 获取院系名称用于成功消息
        SELECT `院系名称` INTO v_院系名称 FROM `院系信息表` WHERE `院系ID` = p_院系ID;
        
        INSERT INTO `课程信息表` (`课程ID`, `课程名称`, `学分`, `院系ID`) 
        VALUES (p_课程ID, p_课程名称, p_学分, p_院系ID);
        SET p_message = CONCAT('✅ 成功添加课程: ', p_课程名称, ' (', p_课程ID, ', ', p_学分, '学分, 所属: ', v_院系名称, ')');
        COMMIT;
    END IF;
END$$
DELIMITER ;

-- 存储过程4: 添加用户(学生/教师/教务)
DROP PROCEDURE IF EXISTS `sp_add_user`;
DELIMITER $$
CREATE PROCEDURE `sp_add_user`(
    IN p_学号_工号 VARCHAR(20),
    IN p_姓名 VARCHAR(50),
    IN p_密码 VARCHAR(255),  -- 实际应用中应该是加密后的密码
    IN p_角色 ENUM('学生','教师','教务'),
    IN p_院系ID INT,
    OUT p_用户ID INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_密码哈希 VARCHAR(255);
    DECLARE v_院系名称 VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_message = '❌ 添加用户失败: 数据库错误';
        SET p_用户ID = -1;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- 参数验证
    IF p_学号_工号 IS NULL OR TRIM(p_学号_工号) = '' THEN
        SET p_message = '❌ 添加失败: 学号/工号不能为空';
        SET p_用户ID = -1;
        ROLLBACK;
    ELSEIF p_姓名 IS NULL OR TRIM(p_姓名) = '' THEN
        SET p_message = '❌ 添加失败: 姓名不能为空';
        SET p_用户ID = -1;
        ROLLBACK;
    ELSEIF p_密码 IS NULL OR TRIM(p_密码) = '' THEN
        SET p_message = '❌ 添加失败: 密码不能为空';
        SET p_用户ID = -1;
        ROLLBACK;
    ELSEIF LENGTH(p_密码) < 6 THEN
        SET p_message = CONCAT('❌ 添加失败: 密码长度不能少于6位 (当前: ', LENGTH(p_密码), '位)');
        SET p_用户ID = -1;
        ROLLBACK;
    -- 检查院系是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `院系信息表` WHERE `院系ID` = p_院系ID) THEN
        SET p_message = CONCAT('❌ 添加失败: 院系ID ', p_院系ID, ' 不存在');
        SET p_用户ID = -1;
        ROLLBACK;
    -- 检查学号/工号是否已存在
    ELSEIF EXISTS (SELECT 1 FROM `用户信息表` WHERE `学号_工号` = p_学号_工号) THEN
        SET p_message = CONCAT('❌ 添加失败: 学号/工号 "', p_学号_工号, '" 已被使用');
        SET p_用户ID = -1;
        ROLLBACK;
    ELSE
        -- 获取院系名称
        SELECT `院系名称` INTO v_院系名称 FROM `院系信息表` WHERE `院系ID` = p_院系ID;
        
        -- 简单的密码哈希(实际应用中应使用更安全的方法)
        SET v_密码哈希 = CONCAT('hash_', MD5(p_密码));
        
        INSERT INTO `用户信息表` (`学号_工号`, `姓名`, `密码哈希`, `角色`, `院系ID`) 
        VALUES (p_学号_工号, p_姓名, v_密码哈希, p_角色, p_院系ID);
        
        SET p_用户ID = LAST_INSERT_ID();
        SET p_message = CONCAT('✅ 成功添加', p_角色, ': ', p_姓名, ' (', p_学号_工号, ', 所属: ', v_院系名称, ', ID: ', p_用户ID, ')');
        COMMIT;
    END IF;
END$$
DELIMITER ;

-- 2. 开课与排课存储过程

-- 存储过程5: 创建开课实例
DROP PROCEDURE IF EXISTS `sp_create_course_instance`;
DELIMITER $$
CREATE PROCEDURE `sp_create_course_instance`(
    IN p_课程ID VARCHAR(20),
    IN p_教室ID INT,
    IN p_学期ID INT,
    IN p_对内名额 INT,
    IN p_对外名额 INT,
    OUT p_开课实例ID INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_教室容量 INT;
    DECLARE v_总名额 INT;
    DECLARE v_课程名称 VARCHAR(100);
    DECLARE v_教室位置 VARCHAR(100);
    DECLARE v_学期名称 VARCHAR(50);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_message = '❌ 创建开课实例失败: 数据库错误';
        SET p_开课实例ID = -1;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- 参数验证
    IF p_课程ID IS NULL OR TRIM(p_课程ID) = '' THEN
        SET p_message = '❌ 创建失败: 课程ID不能为空';
        SET p_开课实例ID = -1;
        ROLLBACK;
    ELSEIF p_对内名额 IS NULL OR p_对内名额 < 0 THEN
        SET p_message = CONCAT('❌ 创建失败: 对内名额不能为负数 (当前: ', COALESCE(p_对内名额, 'NULL'), ')');
        SET p_开课实例ID = -1;
        ROLLBACK;
    ELSEIF p_对外名额 IS NULL OR p_对外名额 < 0 THEN
        SET p_message = CONCAT('❌ 创建失败: 对外名额不能为负数 (当前: ', COALESCE(p_对外名额, 'NULL'), ')');
        SET p_开课实例ID = -1;
        ROLLBACK;
    ELSEIF p_对内名额 + p_对外名额 = 0 THEN
        SET p_message = '❌ 创建失败: 对内名额和对外名额不能同时为0';
        SET p_开课实例ID = -1;
        ROLLBACK;
    -- 检查课程是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `课程信息表` WHERE `课程ID` = p_课程ID) THEN
        SET p_message = CONCAT('❌ 创建失败: 课程ID "', p_课程ID, '" 不存在');
        SET p_开课实例ID = -1;
        ROLLBACK;
    -- 检查教室是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `教室信息表` WHERE `教室ID` = p_教室ID) THEN
        SET p_message = CONCAT('❌ 创建失败: 教室ID ', p_教室ID, ' 不存在');
        SET p_开课实例ID = -1;
        ROLLBACK;
    -- 检查学期是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `学期信息表` WHERE `学期ID` = p_学期ID) THEN
        SET p_message = CONCAT('❌ 创建失败: 学期ID ', p_学期ID, ' 不存在');
        SET p_开课实例ID = -1;
        ROLLBACK;
    ELSE
        -- 获取详细信息
        SELECT `课程名称` INTO v_课程名称 FROM `课程信息表` WHERE `课程ID` = p_课程ID;
        SELECT CONCAT(`教学楼`, ' ', `房间号`), `容量` 
        INTO v_教室位置, v_教室容量 
        FROM `教室信息表` WHERE `教室ID` = p_教室ID;
        SELECT CONCAT(`学年`, ' ', `学期类型`) INTO v_学期名称 FROM `学期信息表` WHERE `学期ID` = p_学期ID;
        
        SET v_总名额 = p_对内名额 + p_对外名额;
        
        -- 检查教室容量
        IF v_总名额 > v_教室容量 THEN
            SET p_message = CONCAT('❌ 创建失败: 总名额(', v_总名额, '人)超过教室"', v_教室位置, '"容量(', v_教室容量, '人)');
            SET p_开课实例ID = -1;
            ROLLBACK;
        ELSE
            INSERT INTO `开课实例表` 
                (`课程ID`, `教室ID`, `学期ID`, `对内名额`, `对外名额`) 
            VALUES 
                (p_课程ID, p_教室ID, p_学期ID, p_对内名额, p_对外名额);
            
            SET p_开课实例ID = LAST_INSERT_ID();
            SET p_message = CONCAT('✅ 成功创建开课实例: ', v_课程名称, ' (', v_学期名称, ', 教室: ', v_教室位置, 
                                   ', 对内名额: ', p_对内名额, ', 对外名额: ', p_对外名额, ', 实例ID: ', p_开课实例ID, ')');
            COMMIT;
        END IF;
    END IF;
END$$
DELIMITER ;

-- 存储过程6: 添加授课教师
DROP PROCEDURE IF EXISTS `sp_assign_teacher`;
DELIMITER $$
CREATE PROCEDURE `sp_assign_teacher`(
    IN p_教师ID INT,
    IN p_开课实例ID INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_角色 ENUM('学生','教师','教务');
    DECLARE v_教师姓名 VARCHAR(50);
    DECLARE v_课程名称 VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_message = '❌ 分配教师失败: 数据库错误';
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- 检查用户是否存在且为教师
    SELECT `角色`, `姓名` INTO v_角色, v_教师姓名
    FROM `用户信息表` 
    WHERE `用户ID` = p_教师ID;
    
    IF v_角色 IS NULL THEN
        SET p_message = CONCAT('❌ 分配失败: 用户ID ', p_教师ID, ' 不存在');
        ROLLBACK;
    ELSEIF v_角色 != '教师' THEN
        SET p_message = CONCAT('❌ 分配失败: 用户"', v_教师姓名, '"的角色是"', v_角色, '"，不是教师');
        ROLLBACK;
    -- 检查开课实例是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `开课实例表` WHERE `开课实例ID` = p_开课实例ID) THEN
        SET p_message = CONCAT('❌ 分配失败: 开课实例ID ', p_开课实例ID, ' 不存在');
        ROLLBACK;
    -- 检查是否已经分配过
    ELSEIF EXISTS (
        SELECT 1 FROM `授课关系表` 
        WHERE `教师ID` = p_教师ID AND `开课实例ID` = p_开课实例ID
    ) THEN
        SET p_message = CONCAT('❌ 分配失败: 教师"', v_教师姓名, '"已分配给该课程');
        ROLLBACK;
    ELSE
        -- 获取课程信息
        SELECT c.`课程名称` INTO v_课程名称
        FROM `开课实例表` oi
        JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
        WHERE oi.`开课实例ID` = p_开课实例ID;
        
        INSERT INTO `授课关系表` (`教师ID`, `开课实例ID`) 
        VALUES (p_教师ID, p_开课实例ID);
        SET p_message = CONCAT('✅ 成功分配: 教师"', v_教师姓名, '"授课"', v_课程名称, '"');
        COMMIT;
    END IF;
END$$
DELIMITER ;

-- 存储过程7: 添加上课时间(含周次和单双周)
DROP PROCEDURE IF EXISTS `sp_add_schedule_time`;
DELIMITER $$
CREATE PROCEDURE `sp_add_schedule_time`(
    IN p_开课实例ID INT,
    IN p_时间段ID INT,
    IN p_教师ID INT,
    IN p_起始周 INT,
    IN p_结束周 INT,
    IN p_单双周 ENUM('全部','单周','双周'),
    OUT p_上课时间ID INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_课程名称 VARCHAR(100);
    DECLARE v_时间描述 VARCHAR(100);
    DECLARE v_教师姓名 VARCHAR(50);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_message = '❌ 添加上课时间失败: 数据库错误';
        SET p_上课时间ID = -1;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- 参数验证
    IF p_起始周 IS NULL OR p_结束周 IS NULL THEN
        SET p_message = '❌ 添加失败: 起始周和结束周不能为空';
        SET p_上课时间ID = -1;
        ROLLBACK;
    ELSEIF p_起始周 < 1 OR p_起始周 > 20 THEN
        SET p_message = CONCAT('❌ 添加失败: 起始周必须在1-20之间 (当前: ', p_起始周, ')');
        SET p_上课时间ID = -1;
        ROLLBACK;
    ELSEIF p_结束周 < 1 OR p_结束周 > 20 THEN
        SET p_message = CONCAT('❌ 添加失败: 结束周必须在1-20之间 (当前: ', p_结束周, ')');
        SET p_上课时间ID = -1;
        ROLLBACK;
    ELSEIF p_结束周 < p_起始周 THEN
        SET p_message = CONCAT('❌ 添加失败: 起始周(', p_起始周, ')不能大于结束周(', p_结束周, ')');
        SET p_上课时间ID = -1;
        ROLLBACK;
    -- 检查开课实例是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `开课实例表` WHERE `开课实例ID` = p_开课实例ID) THEN
        SET p_message = CONCAT('❌ 添加失败: 开课实例ID ', p_开课实例ID, ' 不存在');
        SET p_上课时间ID = -1;
        ROLLBACK;
    -- 检查时间段是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `时间段信息表` WHERE `时间段ID` = p_时间段ID) THEN
        SET p_message = CONCAT('❌ 添加失败: 时间段ID ', p_时间段ID, ' 不存在');
        SET p_上课时间ID = -1;
        ROLLBACK;
    -- 检查教师是否存在(如果提供了教师ID)
    ELSEIF p_教师ID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM `用户信息表` 
        WHERE `用户ID` = p_教师ID AND `角色` = '教师'
    ) THEN
        SET p_message = CONCAT('❌ 添加失败: 教师ID ', p_教师ID, ' 不存在或不是教师');
        SET p_上课时间ID = -1;
        ROLLBACK;
    ELSE
        -- 获取详细信息用于成功消息
        SELECT c.`课程名称` INTO v_课程名称
        FROM `开课实例表` oi
        JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
        WHERE oi.`开课实例ID` = p_开课实例ID;
        
        SELECT CONCAT('周', 
                     CASE `星期` 
                         WHEN 1 THEN '一' WHEN 2 THEN '二' WHEN 3 THEN '三' 
                         WHEN 4 THEN '四' WHEN 5 THEN '五' WHEN 6 THEN '六' WHEN 7 THEN '日'
                     END,
                     ' ', `开始时间`, '-', `结束时间`)
        INTO v_时间描述
        FROM `时间段信息表`
        WHERE `时间段ID` = p_时间段ID;
        
        IF p_教师ID IS NOT NULL THEN
            SELECT `姓名` INTO v_教师姓名 FROM `用户信息表` WHERE `用户ID` = p_教师ID;
        END IF;
        
        -- 触发器会自动检查教师和教室冲突
        INSERT INTO `上课时间表` 
            (`开课实例ID`, `时间段ID`, `教师ID`, `起始周`, `结束周`, `单双周`) 
        VALUES 
            (p_开课实例ID, p_时间段ID, p_教师ID, p_起始周, p_结束周, p_单双周);
        
        SET p_上课时间ID = LAST_INSERT_ID();
        SET p_message = CONCAT('✅ 成功添加上课时间: ', v_课程名称, ', ', v_时间描述, 
                              ', 第', p_起始周, '-', p_结束周, '周(', p_单双周, ')',
                              IF(p_教师ID IS NOT NULL, CONCAT(', 教师: ', v_教师姓名), ''));
        COMMIT;
    END IF;
END$$
DELIMITER ;

-- 3. 学生选课与退课存储过程

-- 存储过程8: 学生选课
DROP PROCEDURE IF EXISTS `sp_student_enroll`;
DELIMITER $$
CREATE PROCEDURE `sp_student_enroll`(
    IN p_学生ID INT,
    IN p_开课实例ID INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_角色 ENUM('学生','教师','教务');
    DECLARE v_学生姓名 VARCHAR(50);
    DECLARE v_课程名称 VARCHAR(100);
    
    -- 移除 EXIT HANDLER，让触发器的具体错误直接返回
    -- 触发器会返回：名额已满、时间冲突、不在选课窗口等具体信息
    
    START TRANSACTION;
    
    -- 检查用户是否存在且为学生
    SELECT `角色`, `姓名` INTO v_角色, v_学生姓名
    FROM `用户信息表` 
    WHERE `用户ID` = p_学生ID;
    
    IF v_角色 IS NULL THEN
        SET p_message = CONCAT('❌ 选课失败: 学生ID ', p_学生ID, ' 不存在');
        ROLLBACK;
    ELSEIF v_角色 != '学生' THEN
        SET p_message = CONCAT('❌ 选课失败: 用户"', v_学生姓名, '"的角色是"', v_角色, '"，不是学生');
        ROLLBACK;
    -- 检查开课实例是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `开课实例表` WHERE `开课实例ID` = p_开课实例ID) THEN
        SET p_message = CONCAT('❌ 选课失败: 开课实例ID ', p_开课实例ID, ' 不存在');
        ROLLBACK;
    ELSE
        -- 获取课程名称
        SELECT c.`课程名称` INTO v_课程名称
        FROM `开课实例表` oi
        JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
        WHERE oi.`开课实例ID` = p_开课实例ID;
        
        -- 触发器会自动检查名额、时间冲突、重复选课、选课时间窗口等
        -- 如果失败，触发器会抛出 SQLSTATE '45000' 并返回具体错误信息
        INSERT INTO `选课记录表` (`学生ID`, `开课实例ID`, `选课时间`) 
        VALUES (p_学生ID, p_开课实例ID, NOW());
        
        SET p_message = CONCAT('✅ 选课成功: ', v_学生姓名, ' 已成功选修《', v_课程名称, '》');
        COMMIT;
    END IF;
END$$
DELIMITER ;

-- 存储过程9: 学生退课
DROP PROCEDURE IF EXISTS `sp_student_drop`;
DELIMITER $$
CREATE PROCEDURE `sp_student_drop`(
    IN p_学生ID INT,
    IN p_开课实例ID INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_学生姓名 VARCHAR(50);
    DECLARE v_课程名称 VARCHAR(100);
    
    -- 移除 EXIT HANDLER，让具体错误直接返回
    
    START TRANSACTION;
    
    -- 检查是否已选该课程
    IF NOT EXISTS (
        SELECT 1 FROM `选课记录表` 
        WHERE `学生ID` = p_学生ID AND `开课实例ID` = p_开课实例ID
    ) THEN
        -- 获取学生和课程信息用于错误提示
        SELECT `姓名` INTO v_学生姓名 FROM `用户信息表` WHERE `用户ID` = p_学生ID;
        SELECT c.`课程名称` INTO v_课程名称
        FROM `开课实例表` oi
        JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
        WHERE oi.`开课实例ID` = p_开课实例ID;
        
        IF v_学生姓名 IS NULL THEN
            SET p_message = CONCAT('❌ 退课失败: 学生ID ', p_学生ID, ' 不存在');
        ELSEIF v_课程名称 IS NULL THEN
            SET p_message = CONCAT('❌ 退课失败: 开课实例ID ', p_开课实例ID, ' 不存在');
        ELSE
            SET p_message = CONCAT('❌ 退课失败: ', v_学生姓名, ' 未选修《', v_课程名称, '》');
        END IF;
        ROLLBACK;
    ELSE
        -- 获取信息用于成功提示
        SELECT u.`姓名`, c.`课程名称`
        INTO v_学生姓名, v_课程名称
        FROM `选课记录表` sc
        JOIN `用户信息表` u ON sc.`学生ID` = u.`用户ID`
        JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
        JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
        WHERE sc.`学生ID` = p_学生ID AND sc.`开课实例ID` = p_开课实例ID;
        
        -- 删除选课记录,触发器会自动更新已选人数
        DELETE FROM `选课记录表` 
        WHERE `学生ID` = p_学生ID AND `开课实例ID` = p_开课实例ID;
        
        SET p_message = CONCAT('✅ 退课成功: ', v_学生姓名, ' 已退选《', v_课程名称, '》');
        COMMIT;
    END IF;
END$$
DELIMITER ;

-- 4. 查询存储过程

-- 存储过程10: 查询学生课表(按学期)
DROP PROCEDURE IF EXISTS `sp_get_student_schedule`;
DELIMITER $$
CREATE PROCEDURE `sp_get_student_schedule`(
    IN p_学生ID INT,
    IN p_学期ID INT
)
BEGIN
    SELECT 
        c.`课程ID`,
        c.`课程名称`,
        c.`学分`,
        ts.`星期`,
        ts.`开始时间`,
        ts.`结束时间`,
        r.`教学楼`,
        r.`房间号`,
        u.`姓名` AS `教师姓名`,
        t.`起始周`,
        t.`结束周`,
        t.`单双周`,
        CONCAT('第', t.`起始周`, '-', t.`结束周`, '周 ', t.`单双周`) AS `周次描述`
    FROM `选课记录表` sc
    JOIN `开课实例表` oi ON sc.`开课实例ID` = oi.`开课实例ID`
    JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
    JOIN `上课时间表` t ON oi.`开课实例ID` = t.`开课实例ID`
    JOIN `时间段信息表` ts ON t.`时间段ID` = ts.`时间段ID`
    JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
    LEFT JOIN `用户信息表` u ON t.`教师ID` = u.`用户ID`
    WHERE sc.`学生ID` = p_学生ID 
      AND oi.`学期ID` = p_学期ID
    ORDER BY ts.`星期`, ts.`开始时间`, t.`起始周`;
END$$
DELIMITER ;

-- 存储过程11: 查询教师课表(按学期)
DROP PROCEDURE IF EXISTS `sp_get_teacher_schedule`;
DELIMITER $$
CREATE PROCEDURE `sp_get_teacher_schedule`(
    IN p_教师ID INT,
    IN p_学期ID INT
)
BEGIN
    SELECT 
        c.`课程ID`,
        c.`课程名称`,
        ts.`星期`,
        ts.`开始时间`,
        ts.`结束时间`,
        r.`教学楼`,
        r.`房间号`,
        t.`起始周`,
        t.`结束周`,
        t.`单双周`,
        CONCAT('第', t.`起始周`, '-', t.`结束周`, '周 ', t.`单双周`) AS `周次描述`,
        oi.`已选对内人数` + oi.`已选对外人数` AS `已选人数`,
        oi.`对内名额` + oi.`对外名额` AS `总名额`
    FROM `授课关系表` tr
    JOIN `开课实例表` oi ON tr.`开课实例ID` = oi.`开课实例ID`
    JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
    JOIN `上课时间表` t ON oi.`开课实例ID` = t.`开课实例ID`
    JOIN `时间段信息表` ts ON t.`时间段ID` = ts.`时间段ID`
    JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
    WHERE tr.`教师ID` = p_教师ID 
      AND oi.`学期ID` = p_学期ID
      AND (t.`教师ID` = p_教师ID OR t.`教师ID` IS NULL)  -- 只显示该教师负责的时间段
    ORDER BY ts.`星期`, ts.`开始时间`, t.`起始周`;
END$$
DELIMITER ;

-- 存储过程12: 查询可选课程(当前学期,有剩余名额)
DROP PROCEDURE IF EXISTS `sp_get_available_courses`;
DELIMITER $$
CREATE PROCEDURE `sp_get_available_courses`(
    IN p_学生ID INT
)
BEGIN
    DECLARE v_学生院系ID INT;
    DECLARE v_学生姓名 VARCHAR(50);
    
    -- 获取学生信息
    SELECT `院系ID`, `姓名` INTO v_学生院系ID, v_学生姓名
    FROM `用户信息表` 
    WHERE `用户ID` = p_学生ID AND `角色` = '学生';
    
    -- 检查学生是否存在
    IF v_学生院系ID IS NULL THEN
        -- 返回空结果集，带错误提示
        SELECT 
            NULL AS `开课实例ID`,
            'ERROR' AS `课程ID`,
            CONCAT('❌ 查询失败: 学生ID ', p_学生ID, ' 不存在或不是学生') AS `课程名称`,
            0 AS `学分`,
            NULL AS `开课院系`,
            NULL AS `教学楼`,
            NULL AS `房间号`,
            0 AS `剩余名额`,
            'ERROR' AS `选课类型`
        WHERE FALSE;  -- 不返回任何行
    ELSE
        SELECT 
            oi.`开课实例ID`,
            c.`课程ID`,
            c.`课程名称`,
            c.`学分`,
            d.`院系名称` AS `开课院系`,
            r.`教学楼`,
            r.`房间号`,
            CASE 
                WHEN c.`院系ID` = v_学生院系ID THEN oi.`对内名额` - oi.`已选对内人数`
                ELSE oi.`对外名额` - oi.`已选对外人数`
            END AS `剩余名额`,
            CASE 
                WHEN c.`院系ID` = v_学生院系ID THEN '本院系'
                ELSE '跨院系'
            END AS `选课类型`
        FROM `开课实例表` oi
        JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
        JOIN `院系信息表` d ON c.`院系ID` = d.`院系ID`
        JOIN `教室信息表` r ON oi.`教室ID` = r.`教室ID`
        JOIN `学期信息表` s ON oi.`学期ID` = s.`学期ID`
        WHERE s.`是否当前学期` = TRUE
          -- 有剩余名额
          AND (
              (c.`院系ID` = v_学生院系ID AND oi.`已选对内人数` < oi.`对内名额`)
              OR
              (c.`院系ID` != v_学生院系ID AND oi.`已选对外人数` < oi.`对外名额`)
          )
          -- 未选过该课程
          AND NOT EXISTS (
              SELECT 1 FROM `选课记录表` 
              WHERE `学生ID` = p_学生ID AND `开课实例ID` = oi.`开课实例ID`
          )
          -- 【关键修复】排除时间冲突的课程（不包括同一门课）
          AND NOT EXISTS (
              SELECT 1
              FROM `选课记录表` sc
              JOIN `上课时间表` t1 ON sc.`开课实例ID` = t1.`开课实例ID`
              JOIN `上课时间表` t2 ON t2.`开课实例ID` = oi.`开课实例ID`
              WHERE sc.`学生ID` = p_学生ID
                AND sc.`开课实例ID` != oi.`开课实例ID`  -- 排除同一门课
                AND t1.`时间段ID` = t2.`时间段ID`
                -- 周次范围重叠检查
                AND t1.`起始周` <= t2.`结束周`
                AND t1.`结束周` >= t2.`起始周`
                -- 单双周冲突检查
                AND (
                    t1.`单双周` = '全部' OR 
                    t2.`单双周` = '全部' OR 
                    t1.`单双周` = t2.`单双周`
                )
          )
        ORDER BY c.`课程ID`;
    END IF;
END$$
DELIMITER ;

-- 5. 实用工具存储过程

-- 存储过程13: 批量导入学生
DROP PROCEDURE IF EXISTS `sp_batch_add_students`;
DELIMITER $$
CREATE PROCEDURE `sp_batch_add_students`(
    IN p_学号前缀 VARCHAR(10),
    IN p_起始编号 INT,
    IN p_数量 INT,
    IN p_院系ID INT,
    OUT p_成功数 INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_计数 INT DEFAULT 0;
    DECLARE v_学号 VARCHAR(20);
    DECLARE v_姓名 VARCHAR(50);
    DECLARE v_用户ID INT;
    DECLARE v_单条消息 VARCHAR(255);
    DECLARE v_院系名称 VARCHAR(100);
    
    SET p_成功数 = 0;
    
    -- 参数验证
    IF p_学号前缀 IS NULL OR TRIM(p_学号前缀) = '' THEN
        SET p_message = '❌ 批量添加失败: 学号前缀不能为空';
        SET p_成功数 = 0;
    ELSEIF p_数量 IS NULL OR p_数量 <= 0 THEN
        SET p_message = CONCAT('❌ 批量添加失败: 数量必须大于0 (当前: ', COALESCE(p_数量, 'NULL'), ')');
        SET p_成功数 = 0;
    ELSEIF p_数量 > 1000 THEN
        SET p_message = CONCAT('❌ 批量添加失败: 一次最多添加1000个学生 (当前: ', p_数量, ')');
        SET p_成功数 = 0;
    ELSEIF NOT EXISTS (SELECT 1 FROM `院系信息表` WHERE `院系ID` = p_院系ID) THEN
        SET p_message = CONCAT('❌ 批量添加失败: 院系ID ', p_院系ID, ' 不存在');
        SET p_成功数 = 0;
    ELSE
        -- 获取院系名称
        SELECT `院系名称` INTO v_院系名称 FROM `院系信息表` WHERE `院系ID` = p_院系ID;
        
        -- 批量添加
        WHILE v_计数 < p_数量 DO
            SET v_学号 = CONCAT(p_学号前缀, LPAD(p_起始编号 + v_计数, 3, '0'));
            SET v_姓名 = CONCAT('学生', LPAD(p_起始编号 + v_计数, 3, '0'));
            
            CALL sp_add_user(v_学号, v_姓名, '123456', '学生', p_院系ID, v_用户ID, v_单条消息);
            
            IF v_用户ID > 0 THEN
                SET p_成功数 = p_成功数 + 1;
            END IF;
            
            SET v_计数 = v_计数 + 1;
        END WHILE;
        
        SET p_message = CONCAT('✅ 批量添加完成: 目标', p_数量, '个, 成功', p_成功数, '个, 失败', 
                              p_数量 - p_成功数, '个 (院系: ', v_院系名称, ')');
    END IF;
END$$
DELIMITER ;

-- 存储过程14: 统计某学期的选课情况
DROP PROCEDURE IF EXISTS `sp_get_enrollment_statistics`;
DELIMITER $$
CREATE PROCEDURE `sp_get_enrollment_statistics`(
    IN p_学期ID INT
)
BEGIN
    SELECT 
        c.`课程ID`,
        c.`课程名称`,
        d.`院系名称`,
        oi.`对内名额`,
        oi.`对外名额`,
        oi.`已选对内人数`,
        oi.`已选对外人数`,
        oi.`已选对内人数` + oi.`已选对外人数` AS `总选课人数`,
        oi.`对内名额` + oi.`对外名额` AS `总名额`,
        CONCAT(
            ROUND((oi.`已选对内人数` + oi.`已选对外人数`) * 100.0 / (oi.`对内名额` + oi.`对外名额`), 2),
            '%'
        ) AS `选课率`
    FROM `开课实例表` oi
    JOIN `课程信息表` c ON oi.`课程ID` = c.`课程ID`
    JOIN `院系信息表` d ON c.`院系ID` = d.`院系ID`
    WHERE oi.`学期ID` = p_学期ID
    ORDER BY c.`课程ID`;
END$$
DELIMITER ;

-- 存储过程创建完成

-- 查看所有存储过程
SELECT 
    ROUTINE_NAME AS '存储过程名称',
    ROUTINE_TYPE AS '类型',
    DTD_IDENTIFIER AS '返回类型',
    ROUTINE_DEFINITION AS '定义'
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = DATABASE()
  AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;



-- 测试数据插入脚本

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. 插入院系信息
INSERT INTO `院系信息表` (`院系名称`) VALUES
('计算机科学与技术学院'),
('软件学院'),
('信息安全学院'),
('数学与统计学院'),
('物理学院');

-- 2. 插入教室信息
INSERT INTO `教室信息表` (`教学楼`, `房间号`, `容量`) VALUES
('教学楼A', '101', 60),
('教学楼A', '102', 80),
('教学楼A', '201', 60),
('教学楼A', '202', 100),
('教学楼B', '101', 50),
('教学楼B', '102', 50),
('教学楼B', '201', 120),
('教学楼C', '101', 40),
('教学楼C', '102', 40),
('教学楼C', '201', 60),
('实验楼', '301', 30),
('实验楼', '302', 30),
('实验楼', '401', 45);

-- 3. 插入时间段信息
-- 注意: 星期字段使用数字 1-7 (1=周一, 2=周二, ..., 7=周日)
INSERT INTO `时间段信息表` (`星期`, `开始时间`, `结束时间`) VALUES
-- 周一 (1)
(1, '08:00:00', '09:40:00'),  -- 时间段1
(1, '10:00:00', '11:40:00'),  -- 时间段2
(1, '14:00:00', '15:40:00'),  -- 时间段3
(1, '16:00:00', '17:40:00'),  -- 时间段4
(1, '19:00:00', '20:40:00'),  -- 时间段5
-- 周二 (2)
(2, '08:00:00', '09:40:00'),  -- 时间段6
(2, '10:00:00', '11:40:00'),  -- 时间段7
(2, '14:00:00', '15:40:00'),  -- 时间段8
(2, '16:00:00', '17:40:00'),  -- 时间段9
(2, '19:00:00', '20:40:00'),  -- 时间段10
-- 周三 (3)
(3, '08:00:00', '09:40:00'),  -- 时间段11
(3, '10:00:00', '11:40:00'),  -- 时间段12
(3, '14:00:00', '15:40:00'),  -- 时间段13
(3, '16:00:00', '17:40:00'),  -- 时间段14
(3, '19:00:00', '20:40:00'),  -- 时间段15
-- 周四 (4)
(4, '08:00:00', '09:40:00'),  -- 时间段16
(4, '10:00:00', '11:40:00'),  -- 时间段17
(4, '14:00:00', '15:40:00'),  -- 时间段18
(4, '16:00:00', '17:40:00'),  -- 时间段19
(4, '19:00:00', '20:40:00'),  -- 时间段20
-- 周五 (5)
(5, '08:00:00', '09:40:00'),  -- 时间段21
(5, '10:00:00', '11:40:00'),  -- 时间段22
(5, '14:00:00', '15:40:00'),  -- 时间段23
(5, '16:00:00', '17:40:00'),  -- 时间段24
(5, '19:00:00', '20:40:00');  -- 时间段25

-- 4. 插入学期信息
INSERT INTO `学期信息表` (`学年`, `学期类型`, `开始日期`, `结束日期`, `选课开始时间`, `选课结束时间`, `是否当前学期`) VALUES
('2023-2024', '秋季', '2023-09-01', '2024-01-15', '2023-08-20 09:00:00', '2023-09-05 17:00:00', FALSE),
('2023-2024', '春季', '2024-02-20', '2024-06-30', '2024-02-01 09:00:00', '2024-02-25 17:00:00', FALSE),
('2024-2025', '秋季', '2024-09-01', '2025-01-15', '2024-08-20 09:00:00', '2024-09-05 17:00:00', FALSE),
('2024-2025', '春季', '2025-02-20', '2025-12-31', '2025-10-01 09:00:00', '2025-12-31 23:59:59', TRUE),
('2025-2026', '秋季', '2025-09-01', '2026-01-15', '2025-08-20 09:00:00', '2025-09-05 17:00:00', FALSE);

-- 5. 插入课程信息
INSERT INTO `课程信息表` (`课程ID`, `课程名称`, `学分`, `院系ID`) VALUES
-- 计算机科学与技术学院课程
('CS101', '数据结构与算法', 4.0, 1),
('CS102', '计算机组成原理', 3.5, 1),
('CS103', '操作系统', 4.0, 1),
('CS201', '计算机网络', 3.5, 1),
('CS202', '编译原理', 3.0, 1),
-- 软件学院课程
('SE101', '软件工程', 3.0, 2),
('SE102', '数据库系统', 4.0, 2),
('SE103', '软件测试', 2.5, 2),
('SE201', 'Web开发技术', 3.0, 2),
('SE202', '移动应用开发', 2.5, 2),
-- 信息安全学院课程
('IS101', '密码学', 3.0, 3),
('IS102', '网络安全', 3.5, 3),
('IS103', '信息安全数学基础', 3.0, 3),
-- 数学与统计学院课程
('MATH101', '高等数学A', 5.0, 4),
('MATH102', '线性代数', 3.0, 4),
('MATH103', '概率论与数理统计', 3.5, 4),
('MATH201', '离散数学', 3.0, 4),
-- 物理学院课程
('PHY101', '大学物理A', 4.0, 5),
('PHY102', '大学物理实验', 1.5, 5);

-- 6. 插入用户信息
INSERT INTO `用户信息表` (`学号_工号`, `姓名`, `密码哈希`, `角色`, `院系ID`) VALUES
-- 教务管理员
('A001', '王教务', 'hash_admin001', '教务', 1),
('A002', '李教务', 'hash_admin002', '教务', 2),
-- 教师 - 计算机学院
('T1001', '张教授', 'hash_teacher001', '教师', 1),
('T1002', '李副教授', 'hash_teacher002', '教师', 1),
('T1003', '王讲师', 'hash_teacher003', '教师', 1),
-- 教师 - 软件学院
('T2001', '赵教授', 'hash_teacher004', '教师', 2),
('T2002', '刘副教授', 'hash_teacher005', '教师', 2),
('T2003', '陈讲师', 'hash_teacher006', '教师', 2),
-- 教师 - 信息安全学院
('T3001', '孙教授', 'hash_teacher007', '教师', 3),
('T3002', '周副教授', 'hash_teacher008', '教师', 3),
-- 教师 - 数学学院
('T4001', '吴教授', 'hash_teacher009', '教师', 4),
('T4002', '郑副教授', 'hash_teacher010', '教师', 4),
('T4003', '钱讲师', 'hash_teacher011', '教师', 4),
-- 教师 - 物理学院
('T5001', '冯教授', 'hash_teacher012', '教师', 5),
('T5002', '陈讲师', 'hash_teacher013', '教师', 5),
-- 学生 - 计算机学院
('2021001', '张三', 'hash_student001', '学生', 1),
('2021002', '李四', 'hash_student002', '学生', 1),
('2021003', '王五', 'hash_student003', '学生', 1),
('2022001', '赵六', 'hash_student004', '学生', 1),
('2022002', '钱七', 'hash_student005', '学生', 1),
('2023001', '孙八', 'hash_student006', '学生', 1),
('2023002', '周九', 'hash_student007', '学生', 1),
('2024001', '吴十', 'hash_student008', '学生', 1),
-- 学生 - 软件学院
('2021101', '郑一', 'hash_student009', '学生', 2),
('2021102', '王二', 'hash_student010', '学生', 2),
('2022101', '刘三', 'hash_student011', '学生', 2),
('2022102', '陈四', 'hash_student012', '学生', 2),
('2023101', '杨五', 'hash_student013', '学生', 2),
('2024101', '黄六', 'hash_student014', '学生', 2),
-- 学生 - 信息安全学院
('2021201', '徐七', 'hash_student015', '学生', 3),
('2022201', '朱八', 'hash_student016', '学生', 3),
('2023201', '林九', 'hash_student017', '学生', 3),
('2024201', '何十', 'hash_student018', '学生', 3),
-- 学生 - 数学学院
('2021301', '高一', 'hash_student019', '学生', 4),
('2022301', '马二', 'hash_student020', '学生', 4),
('2023301', '梁三', 'hash_student021', '学生', 4),
-- 学生 - 物理学院
('2021401', '宋四', 'hash_student022', '学生', 5),
('2022401', '唐五', 'hash_student023', '学生', 5),
('2023401', '许六', 'hash_student024', '学生', 5);

-- 7. 插入开课实例（2024-2025春季学期）
-- 简化版:只开设核心课程,确保无冲突+容量充足
INSERT INTO `开课实例表` (`课程ID`, `教室ID`, `学期ID`, `对内名额`, `对外名额`, `已选对内人数`, `已选对外人数`) VALUES
-- 计算机学院课程
('CS101', 1, 4, 50, 10, 4, 1),    -- 数据结构 [教室1:60容量] 周一1-2,周三1-2
('CS102', 2, 4, 70, 10, 2, 0),    -- 计算机组成原理 [教室2:80容量] 周二1-2,周四3-4
('CS103', 3, 4, 50, 10, 2, 0),    -- 操作系统 [教室3:60容量] 周一3-4,周三5
('CS201', 4, 4, 90, 10, 1, 1),    -- 计算机网络 [教室4:100容量] 周二3-4,周四1-2
-- 软件学院课程
('SE101', 5, 4, 40, 10, 4, 0),    -- 软件工程 [教室5:50容量] 周一5,周三3-4
('SE102', 6, 4, 40, 10, 3, 1),    -- 数据库系统 [教室6:50容量] 周二1-2,周四3-4
('SE103', 8, 4, 30, 10, 1, 0),    -- 软件测试 [教室8:40容量] 周三1-2
('SE201', 9, 4, 30, 10, 2, 0),    -- Web开发 [教室9:40容量] 周四1-2,周五3-4
-- 信息安全学院课程
('IS101', 11, 4, 25, 5, 1, 0),    -- 密码学 [教室11:30容量] 周二3-4,周四1-2
('IS102', 10, 4, 50, 10, 2, 0),   -- 网络安全 [教室10:60容量] 周一1-2,周三3-4
-- 数学学院课程
('MATH101', 7, 4, 100, 20, 1, 1), -- 高等数学A [教室7:120容量] 周二1-2,周四3-4,周五1-2 (修改避免与网络安全冲突)
('MATH102', 3, 4, 50, 10, 1, 2),  -- 线性代数 [改教室3:60容量] 周三3-4,周五3-4 (修改避免与密码学教师冲突)
-- 物理学院课程
('PHY102', 12, 4, 25, 5, 2, 0);   -- 大学物理实验 [教室12:30容量] 周四3-4

-- 8. 插入授课关系
INSERT INTO `授课关系表` (`教师ID`, `开课实例ID`) VALUES
-- 数据结构与算法 - 张教授和王讲师
(3, 1),
(5, 1),
-- 计算机组成原理 - 李副教授
(4, 2),
-- 操作系统 - 张教授
(3, 3),
-- 计算机网络 - 王讲师
(5, 4),
-- 软件工程 - 赵教授
(6, 5),
-- 数据库系统 - 刘副教授和陈讲师
(7, 6),
(8, 6),
-- 软件测试 - 陈讲师
(8, 7),
-- Web开发技术 - 赵教授
(6, 8),
-- 密码学 - 孙教授
(9, 9),
-- 网络安全 - 周副教授
(10, 10),
-- 高等数学A - 吴教授和郑副教授
(11, 11),
(12, 11),
-- 线性代数 - 钱讲师
(13, 12),
-- 大学物理实验 - 陈讲师
(15, 13);

-- 9. 插入上课时间 (修复版:避免教师和学生时间冲突)
INSERT INTO `上课时间表` (`开课实例ID`, `时间段ID`, `教师ID`, `起始周`, `结束周`, `单双周`) VALUES
-- 数据结构与算法 (周一1-2节, 周三1-2节, 全学期) - 分教师授课
(1, 1, 3, 1, 16, '全部'),   -- 周一上午 08:00-09:40 张教授
(1, 2, 3, 1, 16, '全部'),   -- 周一上午 10:00-11:40 张教授  
(1, 11, 5, 1, 16, '全部'),  -- 周三上午 08:00-09:40 王讲师
(1, 12, 5, 1, 16, '全部'),  -- 周三上午 10:00-11:40 王讲师
-- 计算机组成原理 (周二1-2节, 周四3-4节, 前8周理论+后8周实验)
(2, 6, 4, 1, 8, '全部'),    -- 周二上午 08:00-09:40 前8周
(2, 7, 4, 1, 8, '全部'),    -- 周二上午 10:00-11:40 前8周
(2, 18, 4, 9, 16, '全部'),  -- 周四下午 14:00-15:40 后8周
(2, 19, 4, 9, 16, '全部'),  -- 周四下午 16:00-17:40 后8周
-- 操作系统 (周一3-4节, 周三5节, 全学期)
(3, 3, 3, 1, 16, '全部'),   -- 周一下午 14:00-15:40
(3, 4, 3, 1, 16, '全部'),   -- 周一下午 16:00-17:40
(3, 15, 3, 1, 16, '全部'),  -- 周三晚上 19:00-20:40
-- 计算机网络 (周二3-4节, 周四1-2节, 全学期)
(4, 8, 5, 1, 16, '全部'),   -- 周二下午 14:00-15:40
(4, 9, 5, 1, 16, '全部'),   -- 周二下午 16:00-17:40
(4, 16, 5, 1, 16, '全部'),  -- 周四上午 08:00-09:40
(4, 17, 5, 1, 16, '全部'),  -- 周四上午 10:00-11:40
-- 软件工程 (周一5节, 周三3-4节, 全学期)
(5, 5, 6, 1, 16, '全部'),   -- 周一晚上 19:00-20:40
(5, 13, 6, 1, 16, '全部'),  -- 周三下午 14:00-15:40
(5, 14, 6, 1, 16, '全部'),  -- 周三下午 16:00-17:40
-- 数据库系统 (周二1-2节理论, 周四3-4节实验单周) - 分教师授课
(6, 6, 7, 1, 16, '全部'),   -- 周二上午 08:00-09:40 刘副教授 理论
(6, 7, 7, 1, 16, '全部'),   -- 周二上午 10:00-11:40 刘副教授 理论
(6, 18, 8, 1, 16, '单周'),  -- 周四下午 14:00-15:40 陈讲师 实验(单周)
(6, 19, 8, 1, 16, '单周'),  -- 周四下午 16:00-17:40 陈讲师 实验(单周)
-- 软件测试 (周三1-2节, 后8周)
(7, 11, 8, 9, 16, '全部'),  -- 周三上午 08:00-09:40 后8周
(7, 12, 8, 9, 16, '全部'),  -- 周三上午 10:00-11:40 后8周
-- Web开发技术 (周四1-2节, 周五3-4节, 全学期)
(8, 16, 6, 1, 16, '全部'),  -- 周四上午 08:00-09:40
(8, 17, 6, 1, 16, '全部'),  -- 周四上午 10:00-11:40
(8, 23, 6, 1, 16, '全部'),  -- 周五下午 14:00-15:40
(8, 24, 6, 1, 16, '全部'),  -- 周五下午 16:00-17:40
-- 密码学 (周二3-4节, 周四1-2节, 全学期)
(9, 8, 9, 1, 16, '全部'),   -- 周二下午 14:00-15:40
(9, 9, 9, 1, 16, '全部'),   -- 周二下午 16:00-17:40
(9, 16, 9, 1, 16, '全部'),  -- 周四上午 08:00-09:40
(9, 17, 9, 1, 16, '全部'),  -- 周四上午 10:00-11:40
-- 网络安全 (周一3-4节, 周五1-2节, 全学期) - 修改避免与高数冲突
(10, 3, 10, 1, 16, '全部'), -- 周一下午 14:00-15:40
(10, 4, 10, 1, 16, '全部'), -- 周一下午 16:00-17:40
(10, 21, 10, 1, 16, '全部'),-- 周五上午 08:00-09:40
(10, 22, 10, 1, 16, '全部'),-- 周五上午 10:00-11:40
-- 高等数学A (周二1-2节, 周四3-4节, 周五1-2节, 全学期) - 修改避免冲突
(11, 6, 11, 1, 16, '全部'),  -- 周二上午 08:00-09:40 吴教授
(11, 7, 11, 1, 16, '全部'),  -- 周二上午 10:00-11:40 吴教授
(11, 18, 12, 1, 16, '全部'), -- 周四下午 14:00-15:40 郑副教授
(11, 19, 12, 1, 16, '全部'), -- 周四下午 16:00-17:40 郑副教授
(11, 21, 11, 1, 16, '全部'), -- 周五上午 08:00-09:40 吴教授
(11, 22, 11, 1, 16, '全部'), -- 周五上午 10:00-11:40 吴教授
-- 线性代数 (周三3-4节, 周五3-4节, 全学期) - 修改避免教师冲突
(12, 13, 13, 1, 16, '全部'), -- 周三下午 14:00-15:40 钱讲师
(12, 14, 13, 1, 16, '全部'), -- 周三下午 16:00-17:40 钱讲师
(12, 23, 13, 1, 16, '全部'), -- 周五下午 14:00-15:40 钱讲师
(12, 24, 13, 1, 16, '全部'), -- 周五下午 16:00-17:40 钱讲师
-- 大学物理实验 (周四5节+周五5节, 双周, 全学期)
(13, 20, 15, 1, 16, '双周'), -- 周四晚上 19:00-20:40 双周
(13, 25, 15, 1, 16, '双周'); -- 周五晚上 19:00-20:40 双周

-- 10. 插入选课记录 (简化版)
INSERT INTO `选课记录表` (`学生ID`, `开课实例ID`, `选课时间`) VALUES
-- 张三(计算机学院,ID=16)
(16, 1, '2025-10-15 10:00:00'),  -- 数据结构 (本院)
(16, 3, '2025-10-15 10:05:00'),  -- 操作系统 (本院)
(16, 4, '2025-10-15 10:10:00'),  -- 计算机网络 (本院)
-- 李四(计算机学院,ID=17)
(17, 1, '2025-10-15 11:00:00'),  -- 数据结构 (本院)
(17, 2, '2025-10-15 11:05:00'),  -- 计算机组成原理 (本院)
(17, 12, '2025-10-15 11:10:00'), -- 线性代数 (跨院系)
-- 王五(计算机学院,ID=18)
(18, 3, '2025-10-15 12:00:00'),  -- 操作系统 (本院)
-- 赵六(计算机学院,ID=19)
(19, 1, '2025-10-16 09:00:00'),  -- 数据结构 (本院)
(19, 2, '2025-10-16 09:05:00'),  -- 计算机组成原理 (本院)
-- 郑一(软件学院,ID=24)
(24, 1, '2025-10-15 10:00:00'),  -- 数据结构 (跨院系)
(24, 5, '2025-10-15 10:05:00'),  -- 软件工程 (本院)
(24, 6, '2025-10-15 10:10:00'),  -- 数据库系统 (本院)
(24, 8, '2025-10-15 10:15:00'),  -- Web开发 (本院)
-- 王二(软件学院,ID=25)
(25, 5, '2025-10-15 11:00:00'),  -- 软件工程 (本院)
(25, 6, '2025-10-15 11:05:00'),  -- 数据库系统 (本院)
(25, 7, '2025-10-15 11:10:00'),  -- 软件测试 (本院)
-- 刘三(软件学院,ID=26)
(26, 6, '2025-10-15 12:00:00'),  -- 数据库系统 (本院)
(26, 8, '2025-10-15 12:05:00'),  -- Web开发 (本院)
-- 陈四(软件学院,ID=27)
(27, 5, '2025-10-16 09:00:00'),  -- 软件工程 (本院)
-- 徐七(信息安全,ID=29)
(29, 4, '2025-10-15 10:00:00'),  -- 计算机网络 (跨院系)
(29, 10, '2025-10-15 10:05:00'), -- 网络安全 (本院)
-- 朱八(信息安全,ID=30)
(30, 9, '2025-10-15 11:00:00'),  -- 密码学 (本院)
(30, 10, '2025-10-15 11:05:00'), -- 网络安全 (本院)
(30, 6, '2025-10-15 11:10:00'),  -- 数据库系统 (跨院系)
-- 高一(数学学院,ID=35)
(35, 11, '2025-10-15 10:00:00'), -- 高等数学A (本院)
(35, 12, '2025-10-15 10:05:00'), -- 线性代数 (本院)
-- 宋四(物理学院,ID=38)
(38, 11, '2025-10-15 10:00:00'), -- 高等数学A (跨院系)
(38, 13, '2025-10-15 10:05:00'), -- 大学物理实验 (本院)
-- 唐五(物理学院,ID=39)
(39, 12, '2025-10-15 11:00:00'), -- 线性代数 (跨院系)
(39, 13, '2025-10-15 11:10:00'); -- 大学物理实验 (本院)

SET FOREIGN_KEY_CHECKS = 1;