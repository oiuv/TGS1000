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

:: 检查编译结果
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo         编译成功！
    echo ========================================
    echo.
    echo 输出文件: bin\tgs1000.exe
    echo.
    echo 可用命令:
    echo   bin\tgs1000.exe  - 启动游戏服务器
    echo.
) else (
    echo.
    echo ========================================
    echo         编译失败！
    echo ========================================
    echo.
    echo 请检查:
    echo 1. Delphi 7 是否已安装
    echo 2. 环境变量 PATH 是否包含 Delphi 7 路径
    echo 3. 配置文件 tgs1000.cfg 是否正确
    echo.
    echo 常见 Delphi 7 路径:
    echo   C:\Program Files\Borland\Delphi7\Bin
    echo   C:\Program Files (x86)\Borland\Delphi7\Bin
    echo.
)

pause