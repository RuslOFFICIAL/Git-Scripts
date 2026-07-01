@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion

REM .conf files.
if exist "..\.conf-files\Variables.conf" (
    for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf-files\Variables.conf") do set "%%A=%%~B"
)

echo Git-Merge %Git-Merge_Version%&echo.

REM User insert directory path.
set /p DirPath="Enter the path of the Git repository folder (e.g. C:\Path\To\Project): "
cd /d "!DirPath!"

REM Check if it is Git folder.
git rev-parse --is-inside-work-tree >nul 2>&1
if !errorlevel! neq 0 (
    echo.&echo Fatal: This directory is not a Git repository.
    goto end
)

REM Show current status and branches.
echo Current location:
cd
echo.
echo Available branches (Local and Remote):
git branch -a
echo.

REM Switch branch.
set /p SwitchBranch="Enter a branch to switch to (or press ENTER to stay on current): "
if not "!SwitchBranch!"=="" (
    echo.
    echo Switching branch...
    git checkout !SwitchBranch!
    if !errorlevel! neq 0 (
        echo.
        echo Error: Git checkout failed. Script stopped to prevent breaking things.
        goto end
    )
)

echo =======================================

REM Print active branch name out properly.
for /f "delims=" %%i in ('git branch --show-current') do set "CurrentBranch=%%i"
echo You are currently on branch: [ !CurrentBranch! ]
echo.

REM Get input for the target branch.
echo You are about to merge changes INTO [ !CurrentBranch! ]
set /p SourceBranch="Enter the branch you want to merge FROM (e.g., rolling-release): "
if "!SourceBranch!"=="" (
    echo Error: You must specify a source branch.
    goto end
)

set /p AllowUnrelated="Allow unrelated histories? (Y/n) [Default: n]: "

REM Merge.
echo.
echo Running Git merge...

echo Fetching latest branches from GitHub...
git fetch origin

if /i "!AllowUnrelated!"=="y" (
    git merge origin/!SourceBranch! --allow-unrelated-histories -m "Force merge !SourceBranch! history"
) else (
    git merge origin/!SourceBranch!
)

REM Conflicts and Error handling using exclamation format.
if !errorlevel! neq 0 (
    echo.
    echo Merge stopped or failed. 
    echo Hint: If Git says "unmerged files", run 'git merge --abort' in your terminal to reset.
    echo Hint: If it is an actual conflict, resolve the file markers (usually be removing part between <<HEAD and ==) and use Git-Push.
) else (
    echo.
    echo Merge completed successfully!
    
    set /p PushNow="Would you like to push the merged changes to GitHub right now? (Y/n) [Default: y]: "
    if /i "!PushNow!" neq "n" (
        echo Pushing to GitHub...
        git push
    ) else (
        echo Operation cancelled by user.
    )
)

:end
endlocal
echo.&echo Done!
pause