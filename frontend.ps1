# 前端项目一键安装启动脚本

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  高校智能排课选课管理系统 - 前端启动  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查Node.js是否安装
Write-Host "检查 Node.js 环境..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js 已安装: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ 未检测到 Node.js，请先安装 Node.js (建议 v18+)" -ForegroundColor Red
    Write-Host "下载地址: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# 检查npm是否安装
try {
    $npmVersion = npm --version
    Write-Host "✓ npm 已安装: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ npm 未安装" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "开始安装依赖..." -ForegroundColor Yellow
Write-Host ""

# 进入frontend目录
Set-Location -Path "frontend"

# 安装依赖
Write-Host "执行: npm install" -ForegroundColor Cyan
npm install

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ 依赖安装成功！" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  启动开发服务器...                    " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "前端地址: http://localhost:5173" -ForegroundColor Green
    Write-Host "请确保后端服务运行在: http://localhost:8000" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "测试账号:" -ForegroundColor Cyan
    Write-Host "  学生: 2021001 / 123456" -ForegroundColor White
    Write-Host "  教师: T001 / 123456" -ForegroundColor White
    Write-Host "  教务: A001 / 123456" -ForegroundColor White
    Write-Host ""
    Write-Host "按 Ctrl+C 停止服务" -ForegroundColor Yellow
    Write-Host ""
    
    # 启动开发服务器
    npm run dev
} else {
    Write-Host ""
    Write-Host "✗ 依赖安装失败，请检查网络连接或使用淘宝镜像" -ForegroundColor Red
    Write-Host "使用淘宝镜像: npm config set registry https://registry.npmmirror.com" -ForegroundColor Yellow
    exit 1
}
