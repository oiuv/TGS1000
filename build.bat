@echo off
chcp 65001 > nul
echo ========================================
echo      TGS1000 一键编译脚本
echo ========================================
echo.

:: 检查配置文件
if not exist "tgs1000.cfg.example" (
    echo 错误: 缺少配置文件示例 tgs1000.cfg.example
    pause
    exit /b 1
)

:: 复制配置文件（如果不存在）
if not exist "tgs1000.cfg" (
    echo 正在复制配置文件...
    copy "tgs1000.cfg.example" "tgs1000.cfg" > nul
    echo 配置文件已创建: tgs1000.cfg
) else (
    echo 配置文件已存在: tgs1000.cfg
)

:: 创建必要目录
if not exist "bin" mkdir bin
if not exist "dcu" mkdir dcu

echo.
echo 开始编译...
echo.

:: 尝试使用dcc32编译
dcc32 -B tgs1000.dpr

echo.
echo 编译结束...
echo.

pause