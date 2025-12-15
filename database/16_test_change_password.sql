-- =============================================
-- 测试修改密码功能
-- =============================================

USE course_selection_db;

-- 测试1: 修改密码成功
SELECT '测试1: 修改密码成功' AS '测试用例';
CALL sp_change_password(16, '123456', 'newpass123', @msg);
SELECT @msg AS '结果';

-- 验证密码已修改（检查哈希值）
SELECT 
    `用户ID`,
    `学号_工号`,
    `姓名`,
    `密码哈希`,
    CASE 
        WHEN `密码哈希` = CONCAT('hash_', MD5('newpass123')) THEN '✓ 密码已更新'
        ELSE '✗ 密码未更新'
    END AS '验证结果'
FROM `用户信息表`
WHERE `用户ID` = 16;

-- 测试2: 使用新密码再次修改
SELECT '测试2: 使用新密码修改为其他密码' AS '测试用例';
CALL sp_change_password(16, 'newpass123', 'another456', @msg);
SELECT @msg AS '结果';

-- 测试3: 原密码错误
SELECT '测试3: 原密码错误' AS '测试用例';
CALL sp_change_password(16, 'wrongpass', 'newpass789', @msg);
SELECT @msg AS '结果';

-- 测试4: 用户不存在
SELECT '测试4: 用户不存在' AS '测试用例';
CALL sp_change_password(9999, '123456', 'newpass123', @msg);
SELECT @msg AS '结果';

-- 恢复测试数据: 将密码改回123456
SELECT '恢复测试数据' AS '操作';
CALL sp_change_password(16, 'another456', '123456', @msg);
SELECT @msg AS '结果';

-- 最终验证
SELECT 
    `用户ID`,
    `学号_工号`,
    `姓名`,
    CASE 
        WHEN `密码哈希` = CONCAT('hash_', MD5('123456')) THEN '✓ 密码已恢复'
        ELSE '✗ 密码未恢复'
    END AS '验证结果'
FROM `用户信息表`
WHERE `用户ID` = 16;

SELECT '✓ 修改密码功能测试完成' AS '总结';
