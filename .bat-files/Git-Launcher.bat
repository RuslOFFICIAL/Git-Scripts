@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion

REM .conf files.
if exist "..\.conf-files\Variables.conf" (
	for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf-files\Variables.conf") do set "%%A=%%~B"
)

if not exist "..\.conf-files\Git-Launcher_Info.conf" (
	endlocal
	echo Error: Git-Launcher_Info.conf not found!&echo Check if you have that file or follow the instruction in Git-Launcher_Info.conf.example!
	pause
	exit /b
)

echo Git-Launcher %Git-Launcher_Version%&echo.

REM Choices.
set "ChoiceOptions="
set "DisplayOptions="

if exist "..\.conf-files\Git-Launcher_Info.conf" (
	for /f "usebackq tokens=1,2,3 delims=|" %%A in ("..\.conf-files\Git-Launcher_Info.conf") do (
		echo [%%A] %%B
		set "ChoiceOptions=!ChoiceOptions!%%A"
		set "Script_%%A=%%C"
		
		if not defined DisplayOptions (
			set "DisplayOptions=%%A"
		) else (
		set "DisplayOptions=!DisplayOptions!, %%A"
		)
	)
)

if "%ChoiceOptions%"=="" (
	echo Error: No options found in Git-Launcher_Info.conf.
	pause
	exit /b
)
echo.

choice /c !ChoiceOptions! /n /m "Enter your choice (!DisplayOptions!): "
set "UserChoice=!errorlevel!"

REM Results.
set "SelectedScript="
for /f "tokens=1,2,3 delims=|" %%A in ('findstr /b "%UserChoice%|" "..\.conf-files\Git-Launcher_Info.conf"') do (
	set "SelectedScript=%%C"
)

REM End.
:End
echo Running "%SelectedScript%"...&echo.
endlocal&call "%SelectedScript%"
echo.&echo Done!
pause
exit

