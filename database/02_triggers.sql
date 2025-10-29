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
    
    -- 获取学生院系
    SELECT `院系ID` INTO v_学生院系ID
    FROM `用户信息表`
    WHERE `用户ID` = NEW.`学生ID` AND `角色` = '学生';
    
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
    
    -- 3. 检查是否重复选课
    IF EXISTS (
        SELECT 1 FROM `选课记录表`
        WHERE `学生ID` = NEW.`学生ID` 
          AND `开课实例ID` = NEW.`开课实例ID`
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '选课失败: 已选过该课程';
    END IF;
    
    -- 4. 检查时间冲突(考虑周次)
    SELECT COUNT(*) INTO v_冲突数
    FROM `选课记录表` sc
    JOIN `上课时间表` t1 ON sc.`开课实例ID` = t1.`开课实例ID`
    JOIN `上课时间表` t2 ON t2.`开课实例ID` = NEW.`开课实例ID`
    WHERE sc.`学生ID` = NEW.`学生ID`
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