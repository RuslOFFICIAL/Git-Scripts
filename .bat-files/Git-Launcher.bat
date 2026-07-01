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
echo [1] Git-Push
echo [2] Git-Link-Repo
echo [3] Git-Release
echo [4] Git-Merge
echo.

choice /c 1234 /n /m "Enter your choice (1, 2, 3, 4): "

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

<<<<<<< HEAD
=======
:Merge
set "ScriptName=Git-Merge.bat"
goto End

>>>>>>> origin/rolling-release
REM End.
:End
echo Running %ScriptName%...&echo.
endlocal & set "ScriptPath=%~dp0%ScriptName%"
call "%ScriptPath%"
echo.&echo Done!
pause
exit