@echo off
rem Builds the project into demo\DFSDM.elf using the ARM compiler that the
rem STM32 VS Code extension installed. Double-click to run. No board needed.
setlocal enabledelayedexpansion
cd /d "%~dp0.."

for /d %%d in ("%LOCALAPPDATA%\stm32cube\bundles\gnu-tools-for-stm32\*") do set "BIN=%%d\bin"
if not exist "!BIN!\arm-none-eabi-gcc.exe" (
  echo ARM compiler not found. Is the STM32 VS Code extension installed?
  pause
  exit /b 1
)
set "CC=!BIN!\arm-none-eabi-gcc.exe"

set "OBJ=demo/obj"
if exist demo\obj rmdir /s /q demo\obj
mkdir demo\obj

set ARCH=-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard
set RTOS=Middlewares/Third_Party/FreeRTOS/Source
set INC=-ICore/Inc -IDrivers/CMSIS/Device/ST/STM32L4xx/Include -IDrivers/CMSIS/Include -IDrivers/STM32L4xx_HAL_Driver/Inc -IDrivers/STM32L4xx_HAL_Driver/Inc/Legacy -I%RTOS%/CMSIS_RTOS_V2 -I%RTOS%/include -I%RTOS%/portable/GCC/ARM_CM4F
set CFLAGS=%ARCH% -std=gnu11 -g3 -Os -DDEBUG -DUSE_HAL_DRIVER -DSTM32L476xx %INC% -ffunction-sections -fdata-sections -Wall --specs=nano.specs

echo Compiling...
type nul > demo\obj\objs.txt
for %%f in (Core\Src\*.c Drivers\STM32L4xx_HAL_Driver\Src\*.c Middlewares\Third_Party\FreeRTOS\Source\*.c Middlewares\Third_Party\FreeRTOS\Source\CMSIS_RTOS_V2\*.c Middlewares\Third_Party\FreeRTOS\Source\portable\GCC\ARM_CM4F\*.c Middlewares\Third_Party\FreeRTOS\Source\portable\MemMang\heap_4.c) do (
  "!CC!" %CFLAGS% -c "%%f" -o "%OBJ%/%%~nf.o" || goto :fail
  echo %OBJ%/%%~nf.o>> demo\obj\objs.txt
)
"!CC!" %ARCH% -g3 -x assembler-with-cpp -c Core/Startup/startup_stm32l476vgtx.s -o %OBJ%/startup.o || goto :fail
echo %OBJ%/startup.o>> demo\obj\objs.txt

echo Linking...
"!CC!" %ARCH% @demo/obj/objs.txt -T STM32L476VGTX_FLASH.ld --specs=nosys.specs --specs=nano.specs -Wl,-Map=demo/DFSDM.map -Wl,--gc-sections -Wl,--no-warn-rwx-segments -static -Wl,--start-group -lc -lm -Wl,--end-group -o demo/DFSDM.elf || goto :fail
"!BIN!\arm-none-eabi-objcopy.exe" -O ihex demo/DFSDM.elf demo/DFSDM.hex || goto :fail
"!BIN!\arm-none-eabi-size.exe" demo/DFSDM.elf

echo.
echo BUILD OK: demo\DFSDM.elf is ready. Now run flash.bat with the board plugged in.
pause
exit /b 0

:fail
echo.
echo BUILD FAILED - see the error above.
pause
exit /b 1
