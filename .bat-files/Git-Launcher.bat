@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion

REM .conf files.
if exist "..\.conf-files\Variables.conf" (
	for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf-files\Variables.conf") do set "%%A=%%~B"
)

echo Git-Launcher %Git-Launcher_Version%&echo.

REM Choices.
echo What script would you like to run?
echo [1] Git-Push&echo [2] Git-Link-Repo&echo [3] Git-Release&echo [4] Git-Merge& echo [5] Git-Login& echo [6] Git-Aliases
echo.

choice /c 123456 /n /m "Enter your choice (1, 2, 3, 4, 5, 6): "

if %errorlevel%==6 goto Aliases
if %errorlevel%==5 goto Login
if %errorlevel%==4 goto Merge
if %errorlevel%==3 goto Release
if %errorlevel%==2 goto LinkRepo
if %errorlevel%==1 goto Push

REM Results.
:Push
set "ScriptName=Git-Push.bat"
goto End

:LinkRepo
set "ScriptName=Git-Link-Repo.bat"
goto End

:Release
set "ScriptName=Git-Release.bat"
goto End

:Merge
set "ScriptName=Git-Merge.bat"
goto End

:Login
set "ScriptName=Git-Login.bat"
goto End

:Aliases
set "ScriptName=Git-Aliases.bat"
goto End

REM End.
:End
echo Running "%ScriptName%"...&echo.
endlocal & set "ScriptPath=%~dp0%ScriptName%"
call "%ScriptPath%"
echo.&echo Done!
pause
exit
