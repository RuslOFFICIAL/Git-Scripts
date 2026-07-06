@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion

REM .conf files.
if exist "..\.conf-files\Variables.conf" (
	for /f "usebackq eol=# tokens=1,2 delims==" %%A in ("..\.conf-files\Variables.conf") do set "%%A=%%~B"
)

if not exist "..\.conf-files\Git-Aliases_Info.conf" (
	endlocal
	echo Error: Git-Aliases_Info.conf not found!
	echo Check if you have that file or follow the instruction in Git-Aliases_Info.conf.example!
	pause
	exit /b
)

echo Git-Aliases %Git-Aliases_Version%&echo.

REM Variables.
set "Bashrc=%USERPROFILE%\.bashrc"
set "CommandsFile=..\.conf-files\Git-Aliases_Info.conf"

REM Create .bashrc if it doesn't exist yet.
if not exist "%Bashrc%" (
	echo .bashrc not found. Creating a new one...
	type "%CommandsFile%" > "%Bashrc%"
	echo All aliases successfully initialized in a new .bashrc file.
	goto End
)

echo Checking and updating aliases in .bashrc...

REM Read the commands file line by line.
for /f "usebackq eol=# delims=" %%L in ("%CommandsFile%") do (
	REM Extract the alias name.
	for /f "tokens=1 delims==" %%A in ("%%L") do (
		set "ALIAS_CHECK=%%A="
	)
	
	REM Check if the alias definition exists in the file.
	findstr /C:"!ALIAS_CHECK!" "%Bashrc%" >nul 2>&1
	
	if !errorlevel! equ 0 (
		REM Alias found, now check if the exact line matches.
		findstr /x /C:"%%L" "%Bashrc%" >nul 2>&1
		if !errorlevel! neq 0 (
			echo Updating "!ALIAS_CHECK!"...
			
			REM Filter out the old line and create a new temp file.
			findstr /v /C:"!ALIAS_CHECK!" "%Bashrc%" > "%Bashrc%.tmp"
			endlocal & echo %%L>> "%Bashrc%.tmp"
			setlocal enabledelayedexpansion & move /y "%Bashrc%.tmp" "%Bashrc%" >nul
		) else (
			echo Alias "!ALIAS_CHECK!" is already up to date.
		)
	) else (
		REM Append new alias if it does not exist.
		echo.>> "%Bashrc%"
		endlocal & echo %%L>> "%Bashrc%"
		setlocal enabledelayedexpansion & echo Added: "!ALIAS_CHECK!"
	)
)

goto End

:End
endlocal
echo.&echo Done!
pause