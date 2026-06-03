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

set "CN=Control Survey"              & set "CK=CONTROL"    & set "CE=pdf dgn"       & call :check
set "CN=RW Map"                      & set "CK=RW MAP"     & set "CE=pdf dgn"       & call :check
set "CN=Monumentation Map"           & set "CK=MONUMENT"   & set "CE=pdf dgn"       & call :check
set "CN=GPK"                         & set "CK=GPK"        & set "CE=gpk"           & call :check
set "CN=QAQC"                        & set "CK=QAQC"       & set "CE=*"             & call :check
set "CN=Research"                    & set "CK=RESEARCH"   & set "CE=pdf"           & call :check
set "CN=Aerials"                     & set "CK=AERIAL"     & set "CE=sdw sid xml"   & call :check
set "CN=Surveyor's Report"           & set "CK=SURVEYOR"   & set "CE=pdf"           & call :check
set "CN=Roadway"                     & set "CK=ROADWAY"    & set "CE=dgn pdf"       & call :check
set "CN=Field Data"                  & set "CK=FIELD"      & set "CE=txt pdf"       & call :check
set "CN=CCR"                         & set "CK=CCR"        & set "CE=pdf"           & call :check
set "CN=XYZ Printout"               & set "CK=XYZ"        & set "CE=txt xls xlsx"  & call :check
set "CN=Baseline Report"             & set "CK=BASELINE"   & set "CE=txt"           & call :check
set "CN=Plats"                       & set "CK=PLAT"       & set "CE=pdf"           & call :check
set "CN=Tentative Sec. Maps"         & set "CK=TENTATIVE"  & set "CE=pdf"           & call :check
set "CN=Deeds"                       & set "CK=DEED"       & set "CE=pdf"           & call :check
set "CN=Fieldbook & Survey Database" & set "CK=FIELDBOOK"  & set "CE=txt pdf"       & call :check
set "CN=Worksheets"                  & set "CK=WORKSHEET"  & set "CE=dgn pdf"       & call :check

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


:check
set "found_folder="
for /d %%D in ("!DELIVERY!\*") do (
    echo %%~nxD | findstr /i "!CK!" >nul 2>&1
    if !errorlevel!==0 set "found_folder=%%~fD"
)

if "!found_folder!"=="" (
    call :wr "  [MISSING]      !CN!"
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
    set "ext=%%~xF"
    if not "!ext!"=="" (
        set "ext=!ext:~1!"
        set "matched=0"
        if "!CE!"=="*" (
            set "matched=1"
        ) else (
            echo !CE! | findstr /i "!ext!" >nul 2>&1
            if !errorlevel!==0 set "matched=1"
        )
        if "!matched!"=="1" (
            set /a ok_files+=1
            echo !ok_exts! | findstr /i "!ext!" >nul 2>&1
            if !errorlevel!==1 set "ok_exts=!ok_exts! .!ext!"
        ) else (
            set /a diff_files+=1
            echo !diff_exts! | findstr /i "!ext!" >nul 2>&1
            if !errorlevel!==1 set "diff_exts=!diff_exts! .!ext!"
        )
    )
)
popd

if !total_files!==0 (
    call :wr "  [EMPTY]        !CN! - folder found but no files inside"
    set /a empty+=1
) else if !ok_files! gtr 0 (
    if !diff_files! gtr 0 (
        call :wr "  [OK+ALERT]    !CN! (!total_files! files | expected:!ok_exts! | also found:!diff_exts!)"
    ) else (
        call :wr "  [OK]          !CN! (!total_files! files |!ok_exts!)"
    )
    set /a present+=1
) else (
    call :wr "  [ALERT]        !CN! - !total_files! files but none match expected (!CE!) | found:!diff_exts!"
    set /a alerts+=1
)
exit /b


:wr
echo %~1
echo %~1>> "!REPORT!"
exit /b

:wrb
echo.
echo.>> "!REPORT!"
exit /b
