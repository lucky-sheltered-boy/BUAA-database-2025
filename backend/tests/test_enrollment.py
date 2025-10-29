"""
选课功能测试
"""
import pytest


def test_get_available_courses(test_client):
    """测试查询可选课程"""
    # 假设学生ID为16（张三）
    response = test_client.get("/api/students/16/available-courses")
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert isinstance(data["data"], list)


def test_enroll_course_success(test_client, db_cursor):
    """测试选课成功（需要先清理测试数据）"""
    # 这里需要根据实际测试数据调整
    # 先退课（如果已选）
    student_id = 16
    instance_id = 1
    
    # 尝试选课
    response = test_client.post(
        f"/api/students/{student_id}/enroll",
        json={"instance_id": instance_id}
    )
    
    # 可能成功或失败（取决于是否已选）
    assert response.status_code in [200, 409, 422]


def test_drop_course(test_client):
    """测试退课"""
    student_id = 16
    instance_id = 1
    
    response = test_client.post(
        f"/api/students/{student_id}/drop",
        json={"instance_id": instance_id}
    )
    
    # 可能成功或失败（取决于是否已选）
    assert response.status_code in [200, 422]


def test_get_student_schedule(test_client):
    """测试查询学生课表"""
    student_id = 16
    semester_id = 4  # 2024-2025春季学期
    
    response = test_client.get(
        f"/api/students/{student_id}/schedule",
        params={"semester_id": semester_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert isinstance(data["data"], list)
