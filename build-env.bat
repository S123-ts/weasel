@echo off
rem ---------------------------------------------------------------------------
rem 一键构建入口：自动定位 Visual Studio Build Tools 并加载 MSVC 环境，
rem 随后调用项目自带的 build.bat。
rem
rem 用法（在本目录双击，或命令行执行）：
rem   build-env.bat             等价于 build.bat weasel
rem   build-env.bat boost       编译 Boost
rem   build-env.bat rime        编译 librime（x64 + Win32）
rem   build-env.bat data        下载并生成 output\data
rem   build-env.bat weasel      编译 Weasel 本体
rem   build-env.bat all         全量构建
rem   build-env.bat --check     仅检查 MSVC 环境是否可用，不执行构建
rem
rem 自定义：设置环境变量 VCVARS64 指向你的 vcvars64.bat，可跳过自动探测。
rem ---------------------------------------------------------------------------

setlocal EnableExtensions EnableDelayedExpansion

rem --- 1) 环境变量优先 ---
set "VCVARS=%VCVARS64%"

rem --- 2) 定位 vswhere.exe ---
set "VSWHERE="
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not defined VSWHERE if exist "%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe" set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"

rem --- 3) 经临时文件取安装路径，避开 for /f 中括号路径的解析问题 ---
if not defined VCVARS if defined VSWHERE call :probe_vswhere

rem --- 4) 常见安装路径回退 ---
if not defined VCVARS call :probe_common

if not defined VCVARS goto :no_vcvars

if /i "%~1"=="--check" (
  echo [OK] 已定位 MSVC 环境
  echo      !VCVARS!
  exit /b 0
)

echo [1/2] 加载 MSVC 环境
echo       !VCVARS!
call "!VCVARS!" >nul
if errorlevel 1 (
  echo [错误] MSVC 环境加载失败
  exit /b 1
)

cd /d "%~dp0"
echo [2/2] 执行 build.bat %*
echo.
call build.bat %*

set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo.
  echo [失败] build.bat 退出码 %RC%
)
endlocal & exit /b %RC%

rem ---------------------------------------------------------------------------
:probe_vswhere
set "TMPF=%TEMP%\weasel_vspath_%RANDOM%%RANDOM%.txt"
"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath > "%TMPF%" 2>nul
set "VSPATH="
if exist "%TMPF%" set /p VSPATH=<"%TMPF%"
if exist "%TMPF%" del "%TMPF%" >nul 2>nul
if defined VSPATH if exist "!VSPATH!\VC\Auxiliary\Build\vcvars64.bat" set "VCVARS=!VSPATH!\VC\Auxiliary\Build\vcvars64.bat"
exit /b 0

rem ---------------------------------------------------------------------------
:probe_common
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" set "VCVARS=%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if defined VCVARS exit /b 0
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" set "VCVARS=%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
if defined VCVARS exit /b 0
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat" set "VCVARS=%ProgramFiles%\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
if defined VCVARS exit /b 0
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat" set "VCVARS=%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
if defined VCVARS exit /b 0
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat" set "VCVARS=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if defined VCVARS exit /b 0
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" set "VCVARS=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
exit /b 0

rem ---------------------------------------------------------------------------
:no_vcvars
echo [错误] 未找到 vcvars64.bat
echo.
echo   请安装 Visual Studio Build Tools 2022，并勾选「使用 C++ 的桌面开发」
echo   下载地址: https://visualstudio.microsoft.com/visual-cpp-build-tools/
echo.
echo   若已安装但路径特殊，可设置环境变量 VCVARS64 指向 vcvars64.bat 后重试。
exit /b 1
