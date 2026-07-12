@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion

REM .conf files.
if exist "..\.conf-files\Variables.conf" (
	for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf-files\Variables.conf") do set "%%A=%%~B"
)

echo Git-Release %Git-Release_Version%&echo.
goto CompressingProc

REM Compressing process.
:CompressingProc
REM Define paths relative to the script location.
set "SourceDir=.."
set "StagingDir=..\TempRelease"
set "ZipFolder=..\Releases"
set "ZipFile=%ZipFolder%\Git-Scripts_%Git-Scripts_Version%.zip"

echo Cleaning release folder...
for %%f in ("%ZipFolder%\Git-Scripts_*.zip") do (
	echo Removing old ZIP: "%%~nxf"...
	del "%%f" /f /q
)

echo.&echo Preparing release folder (excluding all .conf files)...
robocopy "%SourceDir%" "%StagingDir%" /E /XF *.conf /XD TempRelease Releases .git

echo Including 'Variables.conf' in release...
if not exist "%StagingDir%\.conf-files" mkdir "%StagingDir%\.conf-files"
copy "..\.conf-files\Variables.conf" "%StagingDir%\.conf-files\"

echo.
echo Compressing into .zip file...
REM Create the output directory if it doesn't exist.
if not exist "%ZipFolder%" mkdir "%ZipFolder%"

REM Use PowerShell to compress the staging contents.
powershell -Command "Compress-Archive -Path '%StagingDir%\*' -DestinationPath '%ZipFile%' -Force"

echo.
echo Cleaning up temporary folders...
rmdir /s /q "%StagingDir%"
goto End

REM End.
:End
endlocal
echo.&echo Done!&echo Your release is ready inside the "Releases" folder.
pause
