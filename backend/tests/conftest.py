"""
pytest 配置文件
"""
import pytest
import sys
from pathlib import Path

# 将项目根目录添加到 Python 路径
sys.path.insert(0, str(Path(__file__).parent))


@pytest.fixture(scope="session")
def test_app():
    """测试用 FastAPI 应用"""
    from app.main import app
    return app


@pytest.fixture(scope="session")
def test_client(test_app):
    """测试客户端"""
    from fastapi.testclient import TestClient
    return TestClient(test_app)


@pytest.fixture(scope="function")
def db_cursor():
    """测试用数据库游标"""
    from app.database import db_pool
    with db_pool.get_cursor(commit=True) as cursor:
        yield cursor
