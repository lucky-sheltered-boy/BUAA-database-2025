# 后端服务一键启动脚本

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  高校智能排课选课管理系统 - 后端启动  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查Python是否安装
Write-Host "检查 Python 环境..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version
    Write-Host "✓ Python 已安装: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ 未检测到 Python，请先安装 Python 3.8+" -ForegroundColor Red
    Write-Host "下载地址: https://www.python.org/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 进入backend目录
Set-Location -Path "backend"

# 检查虚拟环境
if (Test-Path "venv") {
    Write-Host "✓ 虚拟环境已存在" -ForegroundColor Green
} else {
    Write-Host "创建虚拟环境..." -ForegroundColor Yellow
    python -m venv venv
    Write-Host "✓ 虚拟环境创建成功" -ForegroundColor Green
}

Write-Host ""
Write-Host "激活虚拟环境..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"

Write-Host ""
Write-Host "安装依赖..." -ForegroundColor Yellow
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ 依赖安装成功！" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  启动后端服务...                      " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "后端地址: http://localhost:8000" -ForegroundColor Green
    Write-Host "API文档: http://localhost:8000/docs" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  请确保已配置 .env 文件中的数据库连接信息" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "按 Ctrl+C 停止服务" -ForegroundColor Yellow
    Write-Host ""
    
    # 启动服务
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
} else {
    Write-Host ""
    Write-Host "✗ 依赖安装失败" -ForegroundColor Red
    exit 1
}
