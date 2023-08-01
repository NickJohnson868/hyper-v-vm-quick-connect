@echo off
chcp 65001

echo 获取当前的执行策略
for /f "usebackq" %%i in (`powershell Get-ExecutionPolicy`) do set currentPolicy=%%i
echo.

echo 当前策略为 %currentPolicy%
echo.

echo 设置策略为RemoteSigned
powershell Set-ExecutionPolicy RemoteSigned
echo.

echo 执行powershell脚本
powershell -File "%~dp0win7.ps1"
echo.

echo 还原策略为 %currentPolicy%
echo.
powershell Set-ExecutionPolicy %currentPolicy%

pause