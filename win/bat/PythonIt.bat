@echo off
title Python���й��� -- Powered_by_SindoSoft

if "%PYTHON_ROOT%" == "" (
	set PYTHON_ROOT=D:\SomeApps\Python\Python2.7
)
set PATH=%PATH%;"%PYTHON_ROOT%\";"%PYTHON_ROOT%\DLLs";"%PYTHON_ROOT%\Lib\site-packages\win32";%PYTHON_ROOT%\Lib\site-packages\pywin32_system32"

if "%1" == "" (
	cd ..\pys
	cmd
)
if not "%1" == "" (
	python %1 %2 %3 %4 %5 %6 %7 %8 %9
	echo.
	pause
)