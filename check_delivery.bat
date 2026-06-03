@echo off
setlocal enabledelayedexpansion

set "DELIVERY=%~1"
set "BATDIR=%~dp0"

if "!DELIVERY!"=="" (
    echo Usage: check_delivery.bat "C:\path\to\delivery\folder"
    pause & exit /b 1
)
if not exist "!DELIVERY!" (
    echo Folder not found: !DELIVERY!
    pause & exit /b 1
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
set "alerts=0"
set "total_expected=18"

call :wr "========================================"
call :wr "  DELIVERY CHECK REPORT"
call :wr "  Project: !DELIVERY!"
call :wr "  Date:    %date% %time:~0,5%"
call :wr "========================================"
call :wrb
call :wr "[ FOLDER ANALYSIS ]"
call :wrb

call :check "Control Survey"              "CONTROL"      "pdf dgn"
call :check "RW Map"                      "RW MAP"       "pdf dgn"
call :check "Monumentation Map"           "MONUMENT"     "pdf dgn"
call :check "GPK"                         "GPK"          "gpk"
call :check "QAQC"                        "QAQC"         "*"
call :check "Research"                    "RESEARCH"     "pdf"
call :check "Aerials"                     "AERIAL"       "sdw sid xml"
call :check "Surveyor's Report"           "SURVEYOR"     "pdf"
call :check "Roadway"                     "ROADWAY"      "dgn pdf"
call :check "Field Data"                  "FIELD"        "txt pdf"
call :check "CCR"                         "CCR"          "pdf"
call :check "XYZ Printout"               "XYZ"          "txt xls xlsx"
call :check "Baseline Report"             "BASELINE"     "txt"
call :check "Plats"                       "PLAT"         "pdf"
call :check "Tentative Sec. Maps"         "TENTATIVE"    "pdf"
call :check "Deeds"                       "DEED"         "pdf"
call :check "Fieldbook & Survey Database" "FIELDBOOK"    "txt pdf"
call :check "Worksheets"                  "WORKSHEET"    "dgn pdf"

set /a score=present*100/total_expected

call :wrb
call :wr "========================================"
call :wr "  SUMMARY"
call :wr "========================================"
call :wr "  Folders with correct content : !present!/!total_expected!"
call :wr "  Folders empty                : !empty!"
call :wr "  Folders missing              : !missing!"
call :wr "  Folders with unexpected files: !alerts!"
call :wrb
call :wr "  COMPLETION: !score!%%"
call :wrb

if !score!==100 (
    call :wr "  STATUS: DELIVERY COMPLETE"
) else if !score! geq 80 (
    call :wr "  STATUS: ALMOST COMPLETE"
) else if !score! geq 50 (
    call :wr "  STATUS: PARTIAL DELIVERY"
) else (
    call :wr "  STATUS: INCOMPLETE DELIVERY"
)

call :wr "========================================"
call :wrb
call :wr "  Report saved to: !REPORT!"

type "!REPORT!"
echo.
echo Report saved to: !REPORT!
pause
exit /b 0


:: ─────────────────────────────────────────────────────────────────────────────
:check
set "catname=%~1"
set "keyword=%~2"
set "exts=%~3"
set "found_folder="

for /d %%D in ("!DELIVERY!\*") do (
    set "dname=%%~nxD"
    echo !dname! | findstr /i "%keyword%" >nul 2>&1
    if !errorlevel!==0 set "found_folder=%%~fD"
)

if "!found_folder!"=="" (
    call :wr "  [MISSING]      %catname%"
    set /a missing+=1
    exit /b
)

set "total_files=0"
set "ok_files=0"
set "diff_files=0"
set "diff_exts="
set "ok_exts="

pushd "!found_folder!"
for /r . %%F in (*.*) do (
    set /a total_files+=1
    set "fext=%%~xF"
    if not "!fext!"=="" (
        set "fext=!fext:~1!"
        call :lower fext
        call :matchext "!fext!" "!exts!" ismatch
        if "!ismatch!"=="1" (
            set /a ok_files+=1
            echo !ok_exts! | findstr /i "!fext!" >nul 2>&1
            if !errorlevel!==1 set "ok_exts=!ok_exts! .!fext!"
        ) else (
            set /a diff_files+=1
            echo !diff_exts! | findstr /i "!fext!" >nul 2>&1
            if !errorlevel!==1 set "diff_exts=!diff_exts! .!fext!"
        )
    )
)
popd

if !total_files!==0 (
    call :wr "  [EMPTY]        %catname% - folder found but no files inside"
    set /a empty+=1
) else if !ok_files! gtr 0 (
    if !diff_files! gtr 0 (
        call :wr "  [OK+ALERT]    %catname% (!total_files! files | expected:!ok_exts! | also found:!diff_exts!)"
        set /a present+=1
    ) else (
        call :wr "  [OK]          %catname% (!total_files! files |!ok_exts!)"
        set /a present+=1
    )
) else (
    call :wr "  [ALERT]        %catname% - !total_files! files, none match expected (%exts%) | found:!diff_exts!"
    set /a alerts+=1
)
exit /b


:: ─────────────────────────────────────────────────────────────────────────────
:matchext
set "%~3=0"
if "%~2"=="*" ( set "%~3=1" & exit /b )
echo  %~2  | findstr /i " %~1 " >nul 2>&1
if !errorlevel!==0 set "%~3=1"
exit /b


:: ─────────────────────────────────────────────────────────────────────────────
:wr
echo %~1
echo %~1>> "!REPORT!"
exit /b

:wrb
echo.
echo.>> "!REPORT!"
exit /b


:: ─────────────────────────────────────────────────────────────────────────────
:lower
for %%A in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do set "%1=!%1:%%A=%%A!"
exit /b
