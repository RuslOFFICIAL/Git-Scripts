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
	set "LINE=%%L"
	
	REM Extract the part before the '=' sign (e.g., "alias git-whoami") to check for duplicates.
	for /f "tokens=1 delims==" %%A in ("%%L") do (
		set "ALIAS_CHECK=%%A="

		REM Search for this exact alias identifier in .bashrc.
		findstr /C:"!ALIAS_CHECK!" "%Bashrc%" >nul
		if !errorlevel! equ 0 (
			echo Alias "!ALIAS_CHECK!" already exists. Skipping...
		) else (
			REM Safely append the raw loop variable to avoid delayed expansion issues with special characters.
			echo.>> "%Bashrc%"
			echo %%L>> "%Bashrc%"
			
			REM Display what was added without breaking the terminal output if special characters exist.
			setlocal disabledelayedexpansion
			echo Added: %%L
			endlocal
		)
	)
)

goto End

:End
endlocal
echo.&echo Done!
pause