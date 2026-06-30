@echo off

REM .conf files.
if exist "..\.conf files\Variables.conf" (
    for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf files\Variables.conf") do set "%%A=%%~B"
)

echo Git-Link-Repo %Git-Link-Repo_Version%&echo.
goto UserInsert

REM User insert information.
:UserInsert
set /p RepoDir="Enter your local repository directory (e.g. C:\Path\To\Project): "
set /p CommitMessage="Enter your commit message: "
set /p RepoLink="Enter your GitHub repository link (e.g. https://github.com/Username/Repository): "
goto NewRepo

REM Linking local files to GitHub repository.
:NewRepo
REM Removing any "" if there any of it.
set "RepoDir=%RepoDir:"=%"
set "RepoLink=%RepoLink:"=%"

cd /d "%RepoDir%"
echo Initializing the local Git folder...
git init
echo Adding all your files...
git add .
echo Adding commit...
git commit -m "%CommitMessage%"
echo Renaming the default branch to 'main'...
git branch -M main
echo Linking your local files to your GitHub repository...
git remote add origin "%RepoLink%"
echo Pushing it to GitHub...
git push -u origin main
goto End

REM End.
:End
endlocal
echo.&echo Done!
pause
