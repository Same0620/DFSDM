@echo off
rem Loads demo\DFSDM.elf onto the board through its ST-LINK USB port.
rem Plug the board in first, then double-click this file.
setlocal enabledelayedexpansion
cd /d "%~dp0"

for /d %%d in ("%LOCALAPPDATA%\stm32cube\bundles\programmer\*") do set "PROG=%%d\bin\STM32_Programmer_CLI.exe"
if not exist "!PROG!" (
  echo STM32 programmer not found. Is the STM32 VS Code extension installed?
  pause
  exit /b 1
)
if not exist DFSDM.elf (
  echo DFSDM.elf is missing - run build.bat first.
  pause
  exit /b 1
)

"!PROG!" -c port=SWD -w DFSDM.elf -v -rst
if errorlevel 1 (
  echo.
  echo First try failed, retrying with connect-under-reset...
  "!PROG!" -c port=SWD mode=UR -w DFSDM.elf -v -rst
)

echo.
if errorlevel 1 (
  echo FLASH FAILED. Check that the board is plugged in through the ST-LINK USB port.
) else (
  echo DONE. The program is on the board and running - it will keep running every time the board has power.
)
pause
