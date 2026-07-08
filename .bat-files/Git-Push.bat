@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion

REM .conf files.
if exist "..\.conf-files\Variables.conf" (
	for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf-files\Variables.conf") do set "%%A=%%~B"
)

if not exist "..\.conf-files\Git-Push_Info.conf" (
	endlocal
	echo Error: Git-Push_Info.conf not found!&echo Check if you have that file or follow the instruction in Git-Push_Info.conf.example!
	pause
	exit /b
)

echo Git-Push %Git-Push_Version%&echo.

REM Choices.
set "ChoiceOptions="
set "DisplayOptions="
for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf-files\Git-Push_Info.conf") do (
	set "Key=%%A"
	set "Rest=%%B"
	
	REM Separate the parameters.
	for /f "tokens=1,2,3 delims=|" %%I in ("!Rest!") do (
		echo [!Key!] %%I
		set "ChoiceOptions=!ChoiceOptions!!Key!"
		set "ProjectPath_!Key!=%%J"
		set "Branch_!Key!=%%K"
		if "!Branch_!Key!!"=="" set "Branch_!Key!=main"
		
		REM Comma.
		if not defined DisplayOptions (
			set "DisplayOptions=!Key!"
		) else (
			set "DisplayOptions=!DisplayOptions!, !Key!"
		)
	)
)
echo.

REM User choice.
choice /c !ChoiceOptions! /n /m "Enter your choice (!DisplayOptions!): "
set "UserChoice=%errorlevel%"

REM Converting.
set /a "Index=%UserChoice%-1"
for %%i in (!Index!) do set "SelectedKey=!ChoiceOptions:~%%i,1!"

REM Directory.
set "TargetDir=!ProjectPath_%SelectedKey%!"

REM Removing any "" if there any of it.
set "TargetDir=%TargetDir:"=%"

if not defined TargetDir (
	echo Invalid selection. Exiting.
	pause
	exit /b
)

cd /d "%TargetDir%"
goto Push

REM Push.
:Push

echo Switching to the branch '!Branch_%SelectedKey%!'...
git switch !Branch_%SelectedKey%!
if errorlevel 1 (
	echo.&echo [ERROR] Failed to switch branch!
	goto ErrorEnd
)

REM Check if there are any changes to commit.
echo Checking if there are any changes to commit...
set "CHANGES="
for /f "tokens=*" %%i in ('git status --porcelain') do set CHANGES=yes

if "%CHANGES%"=="" (
	echo No local changes detected. Just checking for online updates...
	git pull --rebase
if errorlevel 1 (
		echo.&echo [ERROR] Pull failed due to merge conflicts or network issues!
	goto ErrorEnd
	)
	goto End
) else (
	if "%CHANGES%"=="yes" (
		echo Changes has been found.
	)
)

set /p CommitMessage="Enter your commit message: "
echo 1
git add .
echo 2
git commit -m "%CommitMessage%"
echo 32

echo Pulling any changes...
git pull --rebase
if errorlevel 1 (
	echo.&echo [ERROR] Pull failed due to merge conflicts or network issues! &echo Aborting the push process so you can fix it.
	goto ErrorEnd
)

echo Pushing your changes...
git push origin !Branch_%SelectedKey%!
if errorlevel 1 (
	echo.&echo [ERROR] Push failed!
	goto ErrorEnd
)

goto End

:ErrorEnd
endlocal
echo.&echo Script stopped due to an error.
pause
exit /b

:End
endlocal
echo.&echo Done!
pause
