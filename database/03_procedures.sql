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
        oi.`开课实例ID`,  -- 添加开课实例ID，用于退课
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
    SELECT         oi.`开课实例ID`,        c.`课程ID`,
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
                WHEN c.`院系ID` = v_学生院系ID THEN oi.`对内名额`
                ELSE oi.`对外名额`
            END AS `总名额`,
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

-- 存储过程15: 修改用户密码
DROP PROCEDURE IF EXISTS `sp_change_password`;
DELIMITER $$
CREATE PROCEDURE `sp_change_password`(
    IN p_用户ID INT,
    IN p_旧密码 VARCHAR(255),
    IN p_新密码 VARCHAR(255),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_当前密码哈希 VARCHAR(255);
    DECLARE v_新密码哈希 VARCHAR(255);
    
    -- 获取当前密码哈希
    SELECT `密码哈希` INTO v_当前密码哈希
    FROM `用户信息表`
    WHERE `用户ID` = p_用户ID;
    
    -- 验证用户是否存在
    IF v_当前密码哈希 IS NULL THEN
        SET p_message = '❌ 修改密码失败: 用户不存在';
    ELSE
        -- 验证旧密码（使用MD5格式）
        SET v_新密码哈希 = CONCAT('hash_', MD5(p_旧密码));
        
        IF v_当前密码哈希 != v_新密码哈希 THEN
            SET p_message = '❌ 修改密码失败: 原密码不正确';
        ELSE
            -- 生成新密码哈希
            SET v_新密码哈希 = CONCAT('hash_', MD5(p_新密码));
            
            -- 更新密码
            UPDATE `用户信息表`
            SET `密码哈希` = v_新密码哈希
            WHERE `用户ID` = p_用户ID;
            
            SET p_message = '✓ 密码修改成功';
        END IF;
    END IF;
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