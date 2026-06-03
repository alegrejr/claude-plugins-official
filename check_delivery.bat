@echo off
setlocal enabledelayedexpansion

set "DELIVERY=%~1"
set "BATDIR=%~dp0"

if "!DELIVERY!"=="" (
    echo Usage: check_delivery.bat "C:\path\to\delivery\folder"
    pause
    exit /b 1
)

if not exist "!DELIVERY!" (
    echo Folder not found: !DELIVERY!
    pause
    exit /b 1
)

set "hh=%time:~0,2%"
set "mm=%time:~3,2%"
set "hh=!hh: =0!"
set "ts=%date:~-4,4%%date:~-7,2%%date:~0,2%_!hh!!mm!"
set "REPORT=%BATDIR%delivery_report_!ts!.txt"

if exist "!REPORT!" del "!REPORT!"

set "present=0"
set "empty=0"
set "missing=0"
set "extra=0"
set "total_expected=10"

set "f1=1_CONTROL SURVEY"
set "f2=2_RW MAP"
set "f3=3_MONUMENTATION MAP"
set "f4=4_GPK"
set "f5=5_QAQC"
set "f6=6_Research"
set "f7=7_AERIALS"
set "f8=8_Surveyor's Report"
set "f9=9_Roadway"
set "f10=10_Field data"

call :wr "========================================"
call :wr "  DELIVERY CHECK REPORT"
call :wr "  Folder: !DELIVERY!"
call :wr "  Date:   %date% %time:~0,5%"
call :wr "========================================"
call :wr ""
call :wr "[ EXPECTED FOLDERS ]"
call :wr ""

for /l %%i in (1,1,10) do (
    set "fname=!f%%i!"
    set "fpath=!DELIVERY!\!fname!"
    if exist "!fpath!\" (
        set "fcount=0"
        for /r "!fpath!" %%X in (*.*) do set /a fcount+=1
        if !fcount! gtr 0 (
            call :wr "  [OK]      !fname! (!fcount! files)"
            set /a present+=1
        ) else (
            call :wr "  [EMPTY]   !fname! - no files inside"
            set /a empty+=1
        )
    ) else (
        call :wr "  [MISSING] !fname!"
        set /a missing+=1
    )
)

call :wr ""
call :wr "[ UNEXPECTED FOLDERS ]"
call :wr ""

set "extra=0"
for /d %%D in ("!DELIVERY!\*") do (
    set "dname=%%~nxD"
    set "is_expected=0"
    for /l %%i in (1,1,10) do (
        if /i "!dname!"=="!f%%i!" set "is_expected=1"
    )
    if "!is_expected!"=="0" (
        set "xcount=0"
        for /r "%%D" %%X in (*.*) do set /a xcount+=1
        call :wr "  [EXTRA]   !dname! (!xcount! files)"
        set /a extra+=1
    )
)

if !extra!==0 call :wr "  None"

set /a score=present*100/total_expected

call :wr ""
call :wr "========================================"
call :wr "  SUMMARY"
call :wr "========================================"
call :wr "  Complete with content : !present!/!total_expected!"
call :wr "  Present but empty     : !empty!"
call :wr "  Missing               : !missing!"
call :wr "  Unexpected folders    : !extra!"
call :wr ""
call :wr "  COMPLETION: !score!%%"
call :wr ""

if !score!==100 (
    call :wr "  STATUS: DELIVERY COMPLETE"
) else if !score! geq 80 (
    call :wr "  STATUS: ALMOST COMPLETE - review missing items"
) else if !score! geq 50 (
    call :wr "  STATUS: PARTIAL DELIVERY - significant items missing"
) else (
    call :wr "  STATUS: INCOMPLETE DELIVERY"
)

call :wr "========================================"
call :wr ""
call :wr "Report saved to: !REPORT!"

type "!REPORT!"
echo.
echo Report saved to: !REPORT!
pause
exit /b 0


:wr
echo %~1
echo %~1>> "!REPORT!"
exit /b
