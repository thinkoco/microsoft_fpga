@echo off
for /f %%a in ('aocl board-path') do cd /d %%a/windows64/driver
if not %errorlevel%==0 exit /b %errorlevel%
install
if not %errorlevel%==0 exit /b %errorlevel%
