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
        ROLLBACK;
        SET p_message = '添加院系失败: 数据库错误';
        SET p_院系ID = -1;
    END;
    
    START TRANSACTION;
    
    -- 检查院系名称是否已存在
    IF EXISTS (SELECT 1 FROM `院系信息表` WHERE `院系名称` = p_院系名称) THEN
        SET p_message = '添加失败: 院系名称已存在';
        SET p_院系ID = -1;
        ROLLBACK;
    ELSE
        INSERT INTO `院系信息表` (`院系名称`) VALUES (p_院系名称);
        SET p_院系ID = LAST_INSERT_ID();
        SET p_message = CONCAT('成功添加院系: ', p_院系名称);
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
        ROLLBACK;
        SET p_message = '添加教室失败: 数据库错误';
        SET p_教室ID = -1;
    END;
    
    START TRANSACTION;
    
    -- 检查容量是否合法
    IF p_容量 <= 0 THEN
        SET p_message = '添加失败: 教室容量必须大于0';
        SET p_教室ID = -1;
        ROLLBACK;
    -- 检查教室是否已存在
    ELSEIF EXISTS (
        SELECT 1 FROM `教室信息表` 
        WHERE `教学楼` = p_教学楼 AND `房间号` = p_房间号
    ) THEN
        SET p_message = '添加失败: 该教室已存在';
        SET p_教室ID = -1;
        ROLLBACK;
    ELSE
        INSERT INTO `教室信息表` (`教学楼`, `房间号`, `容量`) 
        VALUES (p_教学楼, p_房间号, p_容量);
        SET p_教室ID = LAST_INSERT_ID();
        SET p_message = CONCAT('成功添加教室: ', p_教学楼, ' ', p_房间号);
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
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = '添加课程失败: 数据库错误';
    END;
    
    START TRANSACTION;
    
    -- 检查学分是否合法
    IF p_学分 <= 0 THEN
        SET p_message = '添加失败: 学分必须大于0';
        ROLLBACK;
    -- 检查院系是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `院系信息表` WHERE `院系ID` = p_院系ID) THEN
        SET p_message = '添加失败: 院系不存在';
        ROLLBACK;
    -- 检查课程ID是否已存在
    ELSEIF EXISTS (SELECT 1 FROM `课程信息表` WHERE `课程ID` = p_课程ID) THEN
        SET p_message = '添加失败: 课程ID已存在';
        ROLLBACK;
    ELSE
        INSERT INTO `课程信息表` (`课程ID`, `课程名称`, `学分`, `院系ID`) 
        VALUES (p_课程ID, p_课程名称, p_学分, p_院系ID);
        SET p_message = CONCAT('成功添加课程: ', p_课程名称, ' (', p_课程ID, ')');
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
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = '添加用户失败: 数据库错误';
        SET p_用户ID = -1;
    END;
    
    START TRANSACTION;
    
    -- 检查院系是否存在
    IF NOT EXISTS (SELECT 1 FROM `院系信息表` WHERE `院系ID` = p_院系ID) THEN
        SET p_message = '添加失败: 院系不存在';
        SET p_用户ID = -1;
        ROLLBACK;
    -- 检查学号/工号是否已存在
    ELSEIF EXISTS (SELECT 1 FROM `用户信息表` WHERE `学号_工号` = p_学号_工号) THEN
        SET p_message = '添加失败: 学号/工号已存在';
        SET p_用户ID = -1;
        ROLLBACK;
    ELSE
        -- 简单的密码哈希(实际应用中应使用更安全的方法)
        SET v_密码哈希 = CONCAT('hash_', MD5(p_密码));
        
        INSERT INTO `用户信息表` (`学号_工号`, `姓名`, `密码哈希`, `角色`, `院系ID`) 
        VALUES (p_学号_工号, p_姓名, v_密码哈希, p_角色, p_院系ID);
        
        SET p_用户ID = LAST_INSERT_ID();
        SET p_message = CONCAT('成功添加', p_角色, ': ', p_姓名, ' (', p_学号_工号, ')');
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
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = '创建开课实例失败: 数据库错误';
        SET p_开课实例ID = -1;
    END;
    
    START TRANSACTION;
    
    -- 检查课程是否存在
    IF NOT EXISTS (SELECT 1 FROM `课程信息表` WHERE `课程ID` = p_课程ID) THEN
        SET p_message = '创建失败: 课程不存在';
        SET p_开课实例ID = -1;
        ROLLBACK;
    -- 检查教室是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `教室信息表` WHERE `教室ID` = p_教室ID) THEN
        SET p_message = '创建失败: 教室不存在';
        SET p_开课实例ID = -1;
        ROLLBACK;
    -- 检查学期是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `学期信息表` WHERE `学期ID` = p_学期ID) THEN
        SET p_message = '创建失败: 学期不存在';
        SET p_开课实例ID = -1;
        ROLLBACK;
    ELSE
        -- 获取教室容量并检查(触发器会再次检查,这里提前检查提供更好的错误信息)
        SELECT `容量` INTO v_教室容量 FROM `教室信息表` WHERE `教室ID` = p_教室ID;
        SET v_总名额 = p_对内名额 + p_对外名额;
        
        IF v_总名额 > v_教室容量 THEN
            SET p_message = CONCAT('创建失败: 总名额(', v_总名额, ')超过教室容量(', v_教室容量, ')');
            SET p_开课实例ID = -1;
            ROLLBACK;
        ELSE
            INSERT INTO `开课实例表` 
                (`课程ID`, `教室ID`, `学期ID`, `对内名额`, `对外名额`) 
            VALUES 
                (p_课程ID, p_教室ID, p_学期ID, p_对内名额, p_对外名额);
            
            SET p_开课实例ID = LAST_INSERT_ID();
            SET p_message = CONCAT('成功创建开课实例,ID: ', p_开课实例ID);
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
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = '分配教师失败: 数据库错误';
    END;
    
    START TRANSACTION;
    
    -- 检查用户是否存在且为教师
    SELECT `角色` INTO v_角色 
    FROM `用户信息表` 
    WHERE `用户ID` = p_教师ID;
    
    IF v_角色 IS NULL THEN
        SET p_message = '分配失败: 教师不存在';
        ROLLBACK;
    ELSEIF v_角色 != '教师' THEN
        SET p_message = '分配失败: 该用户不是教师';
        ROLLBACK;
    -- 检查开课实例是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `开课实例表` WHERE `开课实例ID` = p_开课实例ID) THEN
        SET p_message = '分配失败: 开课实例不存在';
        ROLLBACK;
    -- 检查是否已经分配过
    ELSEIF EXISTS (
        SELECT 1 FROM `授课关系表` 
        WHERE `教师ID` = p_教师ID AND `开课实例ID` = p_开课实例ID
    ) THEN
        SET p_message = '分配失败: 该教师已分配给此课程';
        ROLLBACK;
    ELSE
        INSERT INTO `授课关系表` (`教师ID`, `开课实例ID`) 
        VALUES (p_教师ID, p_开课实例ID);
        SET p_message = '成功分配教师';
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
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        SET p_message = CONCAT('添加上课时间失败: ', @text);
        SET p_上课时间ID = -1;
    END;
    
    START TRANSACTION;
    
    -- 检查周次范围
    IF p_起始周 < 1 OR p_起始周 > 20 OR p_结束周 < 1 OR p_结束周 > 20 THEN
        SET p_message = '添加失败: 周次范围必须在1-20之间';
        SET p_上课时间ID = -1;
        ROLLBACK;
    ELSEIF p_结束周 < p_起始周 THEN
        SET p_message = '添加失败: 结束周不能小于起始周';
        SET p_上课时间ID = -1;
        ROLLBACK;
    ELSE
        -- 触发器会自动检查教师和教室冲突
        INSERT INTO `上课时间表` 
            (`开课实例ID`, `时间段ID`, `教师ID`, `起始周`, `结束周`, `单双周`) 
        VALUES 
            (p_开课实例ID, p_时间段ID, p_教师ID, p_起始周, p_结束周, p_单双周);
        
        SET p_上课时间ID = LAST_INSERT_ID();
        SET p_message = CONCAT('成功添加上课时间,ID: ', p_上课时间ID);
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
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        SET p_message = @text;
    END;
    
    START TRANSACTION;
    
    -- 检查用户是否存在且为学生
    SELECT `角色` INTO v_角色 
    FROM `用户信息表` 
    WHERE `用户ID` = p_学生ID;
    
    IF v_角色 IS NULL THEN
        SET p_message = '选课失败: 学生不存在';
        ROLLBACK;
    ELSEIF v_角色 != '学生' THEN
        SET p_message = '选课失败: 该用户不是学生';
        ROLLBACK;
    -- 检查开课实例是否存在
    ELSEIF NOT EXISTS (SELECT 1 FROM `开课实例表` WHERE `开课实例ID` = p_开课实例ID) THEN
        SET p_message = '选课失败: 开课实例不存在';
        ROLLBACK;
    ELSE
        -- 触发器会自动检查名额、时间冲突、重复选课等
        INSERT INTO `选课记录表` (`学生ID`, `开课实例ID`, `选课时间`) 
        VALUES (p_学生ID, p_开课实例ID, NOW());
        
        SET p_message = '选课成功';
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
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = '退课失败: 数据库错误';
    END;
    
    START TRANSACTION;
    
    -- 检查是否已选该课程
    IF NOT EXISTS (
        SELECT 1 FROM `选课记录表` 
        WHERE `学生ID` = p_学生ID AND `开课实例ID` = p_开课实例ID
    ) THEN
        SET p_message = '退课失败: 未选该课程';
        ROLLBACK;
    ELSE
        -- 删除选课记录,触发器会自动更新已选人数
        DELETE FROM `选课记录表` 
        WHERE `学生ID` = p_学生ID AND `开课实例ID` = p_开课实例ID;
        
        SET p_message = '退课成功';
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
    
    -- 获取学生院系
    SELECT `院系ID` INTO v_学生院系ID 
    FROM `用户信息表` 
    WHERE `用户ID` = p_学生ID;
    
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
    ORDER BY c.`课程ID`;
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
    
    SET p_成功数 = 0;
    
    WHILE v_计数 < p_数量 DO
        SET v_学号 = CONCAT(p_学号前缀, LPAD(p_起始编号 + v_计数, 3, '0'));
        SET v_姓名 = CONCAT('学生', LPAD(p_起始编号 + v_计数, 3, '0'));
        
        CALL sp_add_user(v_学号, v_姓名, '123456', '学生', p_院系ID, v_用户ID, v_单条消息);
        
        IF v_用户ID > 0 THEN
            SET p_成功数 = p_成功数 + 1;
        END IF;
        
        SET v_计数 = v_计数 + 1;
    END WHILE;
    
    SET p_message = CONCAT('批量添加完成: 成功', p_成功数, '个,失败', p_数量 - p_成功数, '个');
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