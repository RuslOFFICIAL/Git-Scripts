@echo off
setlocal enabledelayedexpansion

REM .conf files.

if exist "..\.conf-files\Variables.conf" (
	for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf-files\Variables.conf") do set "%%A=%%~B"
)

if not exist "..\.conf-files\Git-Login_Info.conf" (
	echo Error: Git-Login_Info.conf not found!&echo Check if you have that file or follow the instruction in Git-Login_Info.conf.example!
	pause
	exit /b
)

echo Git-Login %Git-Login_Version%&echo.

REM Variables.
for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf-files\Git-Login_Info.conf") do set "%%A=%%~B"
endlocal & set "LoginName=%GitName%" & set "LoginEmail=%GitEmail%"

goto Login

REM Login process.
:Login
<nul set /p ="Setting username... "
git config --global user.name "%LoginName%"
echo Success!

<nul set /p ="Setting user email... "
git config --global user.email "%LoginEmail%"
echo Success!
goto End

REM End.
:End
echo.& echo Git global configuration updated successfully!
echo Username: %LoginName%& echo Email:    %LoginEmail%
pause