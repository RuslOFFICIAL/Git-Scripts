@echo off
setlocal enabledelayedexpansion

REM .conf files.
if exist "..\.conf\Variables.conf" (
    for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf\Variables.conf") do set "%%A=%%~B"
)

if not exist "..\.conf\Git-Push_Info.conf" (
    echo Error: Git-Push_Info.conf not found!
    pause
    exit /b
)

echo Git-Push %Git-Push_Version%&echo.

REM Choices.
set "ChoiceOptions="
set "DisplayOptions="
for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf\Git-Push_Info.conf") do (
    set "Key=%%A"
    set "Rest=%%B"
    
    REM Separate the name and path.
    for /f "tokens=1,2 delims=|" %%I in ("!Rest!") do (
        echo [!Key!] %%I
        set "ChoiceOptions=!ChoiceOptions!!Key!"
        set "ProjectPath_!Key!=%%J"
	
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
REM Check if there are any changes to commit.
set "CHANGES="
for /f "tokens=*" %%i in ('git status --porcelain') do set CHANGES=yes

if "%CHANGES%"=="" (
    echo No local changes detected. Just checking for online updates...
    git pull --rebase
    goto End
)

set /p CommitMessage="Enter your commit message: "
git add .
git commit -m "%CommitMessage%"
echo Pulling any changes...
git pull --rebase
echo Pushing your changes...
git push

:End
endlocal
echo.&echo Done!
pause
