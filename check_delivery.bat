@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: check_delivery.bat "C:\path\to\delivery\folder"
    pause
    exit /b 1
)

set "DELIVERY=%~1"

if not exist "%DELIVERY%" (
    echo Folder not found: %DELIVERY%
    pause
    exit /b 1
)

set "REPORT=%DELIVERY%\delivery_report_%date:~-4,4%%date:~-7,2%%date:~0,2%_%time:~0,2%%time:~3,2%.txt"
set "REPORT=%REPORT: =0%"

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

call :write_report "========================================"
call :write_report "  DELIVERY CHECK REPORT"
call :write_report "  Folder: %DELIVERY%"
call :write_report "  Date:   %date% %time:~0,5%"
call :write_report "========================================"
call :write_report ""
call :write_report "[ EXPECTED FOLDERS ]"
call :write_report ""

for /l %%i in (1,1,10) do (
    set "fname=!f%%i!"
    set "fpath=%DELIVERY%\!fname!"
    if exist "!fpath!\" (
        set "fcount=0"
        for /r "!fpath!" %%X in (*.*) do set /a fcount+=1
        if !fcount! gtr 0 (
            call :write_report "  [OK] !fname! (!fcount! files)"
            set /a present+=1
        ) else (
            call :write_report "  [EMPTY] !fname! - folder exists but no files"
            set /a empty+=1
        )
    ) else (
        call :write_report "  [MISSING] !fname!"
        set /a missing+=1
    )
)

call :write_report ""
call :write_report "[ UNEXPECTED FOLDERS ]"
call :write_report ""

for /d %%D in ("%DELIVERY%\*") do (
    set "dname=%%~nxD"
    set "is_expected=0"
    for /l %%i in (1,1,10) do (
        if /i "!dname!"=="!f%%i!" set "is_expected=1"
    )
    if "!is_expected!"=="0" (
        set "xcount=0"
        for /r "%%D" %%X in (*.*) do set /a xcount+=1
        call :write_report "  [EXTRA] !dname! (!xcount! files)"
        set /a extra+=1
    )
)

if %extra%==0 call :write_report "  None"

set /a score=present*100/total_expected

call :write_report ""
call :write_report "========================================"
call :write_report "  SUMMARY"
call :write_report "========================================"
call :write_report "  Complete with content : %present%/%total_expected%"
call :write_report "  Present but empty     : %empty%"
call :write_report "  Missing               : %missing%"
call :write_report "  Unexpected folders    : %extra%"
call :write_report ""
call :write_report "  COMPLETION: %score%%"
call :write_report ""

if %score%==100 (
    call :write_report "  STATUS: DELIVERY COMPLETE"
) else if %score% geq 80 (
    call :write_report "  STATUS: ALMOST COMPLETE - review missing items"
) else if %score% geq 50 (
    call :write_report "  STATUS: PARTIAL DELIVERY - significant items missing"
) else (
    call :write_report "  STATUS: INCOMPLETE DELIVERY"
)

call :write_report "========================================"

type "%REPORT%"
echo.
echo Report saved to: %REPORT%
pause
exit /b 0


:write_report
echo %~1
echo %~1 >> "%REPORT%"
exit /b
