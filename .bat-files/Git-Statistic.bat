@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion

REM .conf files.
if exist "..\.conf-files\Variables.conf" (
	for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf-files\Variables.conf") do set "%%A=%%~B"
)

echo Git-Statistic %Git-Statistic_Version%&echo.

REM Variables.
for /f "tokens=*" %%i in ('git config user.name') do set git_name=%%i
set total_added=0
set total_removed=0
set total_commits=0

goto PathInput

REM Path.
:PathInput
set /p target_dir="Enter the directory path of the directory with .git folder or with subdirectory with .git folder: "

if not exist "%target_dir%" (
	endlocal
	echo Directory not found!
	pause
	exit /b
)
cd /d "%target_dir%"

goto Stats

REM Loop through directories.
:Stats
set "found_any="

REM Check if the target directory is a repository.
if exist ".git" (
	set "found_any=1"
	call :ProcessRepo "." "%target_dir%"
)

REM Loop through subdirectories.
for /d %%d in (*) do (
	set "is_repo="
	if exist "%%d\.git" set "is_repo=1"
	if /i "%%d"==".git" set "is_repo=1"
	
	if defined is_repo (
		set "found_any=1"
		call :ProcessRepo "%%d" "%%d"
	)
)

REM Check if any were found
if not defined found_any (
	echo No git repositories found in this directory.
	pause
	exit /b
)

goto Summary

REM Summary.
:Summary

REM Separator.
for /f "tokens=2 delims=:" %%c in ('mode con ^| findstr Columns') do set /a width=%%c-1
set "line="
for /l %%i in (1,1,%width%) do set "line=!line!-"
powershell -Command "[Console]::CursorTop -= 1; [Console]::Write(' ' * [Console]::BufferWidth); [Console]::CursorLeft = 0"
echo !line!

REM Total.
echo Grand Total Commits: !total_commits!
echo Grand Total Added: !total_added!
echo Grand Total Removed: !total_removed!

goto End

REM End.
:End
endlocal
echo.&echo Done!
pause
exit /b

REM If the target directory is a repository.
:ProcessRepo
pushd "%~1"
echo Stats for %~2\

REM Get commits.
for /f %%c in ('git rev-list --count --author="%git_name%" HEAD') do set commits=%%c

REM Get stats.
set add=0
set del=0
for /f "tokens=1,2" %%a in ('git log --author="%git_name%" --numstat --pretty^=format: ^| findstr /r "^[0-9]"') do (
	set /a add+=%%a
	set /a del+=%%b
)

echo Commits: !commits! ^| Added: !add! ^| Removed: !del!&echo.

set /a total_added+=add
set /a total_removed+=del
set /a total_commits+=commits

popd
exit /b