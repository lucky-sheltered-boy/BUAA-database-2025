"""
自定义异常类
"""
from typing import Optional, Any


class BaseAPIException(Exception):
    """API 异常基类"""
    
    def __init__(
        self,
        message: str,
        status_code: int = 400,
        code: str = "ERROR",
        details: Optional[Any] = None
    ):
        self.message = message
        self.status_code = status_code
        self.code = code
        self.details = details
        super().__init__(self.message)


class DatabaseError(BaseAPIException):
    """数据库错误"""
    
    def __init__(self, message: str, details: Optional[Any] = None):
        super().__init__(
            message=message,
            status_code=500,
            code="DATABASE_ERROR",
            details=details
        )


class AuthenticationError(BaseAPIException):
    """认证错误"""
    
    def __init__(self, message: str = "认证失败"):
        super().__init__(
            message=message,
            status_code=401,
            code="AUTHENTICATION_ERROR"
        )


class AuthorizationError(BaseAPIException):
    """授权错误"""
    
    def __init__(self, message: str = "权限不足"):
        super().__init__(
            message=message,
            status_code=403,
            code="AUTHORIZATION_ERROR"
        )


class ValidationError(BaseAPIException):
    """验证错误"""
    
    def __init__(self, message: str, details: Optional[Any] = None):
        super().__init__(
            message=message,
            status_code=400,
            code="VALIDATION_ERROR",
            details=details
        )


class NotFoundError(BaseAPIException):
    """资源未找到"""
    
    def __init__(self, message: str = "资源不存在"):
        super().__init__(
            message=message,
            status_code=404,
            code="NOT_FOUND"
        )


class ConflictError(BaseAPIException):
    """冲突错误（如重复选课、时间冲突等）"""
    
    def __init__(self, message: str, details: Optional[Any] = None):
        super().__init__(
            message=message,
            status_code=409,
            code="CONFLICT_ERROR",
            details=details
        )


class BusinessError(BaseAPIException):
    """业务逻辑错误"""
    
    def __init__(self, message: str, details: Optional[Any] = None):
        super().__init__(
            message=message,
            status_code=422,
            code="BUSINESS_ERROR",
            details=details
        )
