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
set "TMPEXTS=%TEMP%\chkdel_exts.txt"
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

set "CN=Control Survey"              & set "CK=CONTROL"    & set "CE=pdf dgn"      & call :check
set "CN=RW Map"                      & set "CK=RW MAP"     & set "CE=pdf dgn"      & call :check
set "CN=Monumentation Map"           & set "CK=MONUMENT"   & set "CE=pdf dgn"      & call :check
set "CN=GPK"                         & set "CK=GPK"        & set "CE=gpk"          & call :check
set "CN=QAQC"                        & set "CK=QAQC"       & set "CE=*"            & call :check
set "CN=Research"                    & set "CK=RESEARCH"   & set "CE=pdf"          & call :check
set "CN=Aerials"                     & set "CK=AERIAL"     & set "CE=sdw sid xml"  & call :check
set "CN=Surveyor Report"             & set "CK=SURVEYOR"   & set "CE=pdf"          & call :check
set "CN=Roadway"                     & set "CK=ROADWAY"    & set "CE=dgn pdf"      & call :check
set "CN=Field Data"                  & set "CK=FIELD"      & set "CE=txt pdf"      & call :check
set "CN=CCR"                         & set "CK=CCR"        & set "CE=pdf"          & call :check
set "CN=XYZ Printout"               & set "CK=XYZ"        & set "CE=txt xls xlsx" & call :check
set "CN=Baseline Report"             & set "CK=BASELINE"   & set "CE=txt"          & call :check
set "CN=Plats"                       & set "CK=PLAT"       & set "CE=pdf"          & call :check
set "CN=Tentative Sec Maps"          & set "CK=TENTATIVE"  & set "CE=pdf"          & call :check
set "CN=Deeds"                       & set "CK=DEED"       & set "CE=pdf"          & call :check
set "CN=Fieldbook Survey Database"   & set "CK=FIELDBOOK"  & set "CE=txt pdf"      & call :check
set "CN=Worksheets"                  & set "CK=WORKSHEET"  & set "CE=dgn pdf"      & call :check

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


:: ════════════════════════════════════════════════════════════════════════
:check
set "found_folder="
for /d %%D in ("!DELIVERY!\*") do (
    echo %%~nxD | findstr /i "!CK!" >nul 2>&1
    if !errorlevel!==0 set "found_folder=%%~fD"
)

if "!found_folder!"=="" (
    call :wr "  [MISSING]   !CN!"
    set /a missing+=1
    exit /b
)

:: Step 1 — count files and dump extensions to temp file (simple loop, no logic inside)
set "file_count=0"
if exist "!TMPEXTS!" del "!TMPEXTS!"
pushd "!found_folder!"
for /r . %%F in (*.*) do (
    set /a file_count+=1
    echo %%~xF>> "!TMPEXTS!"
)
popd

if !file_count!==0 (
    call :wr "  [EMPTY]     !CN! - folder found but no files inside"
    set /a empty+=1
    exit /b
)

:: Step 2 — build unique extension list from temp file
set "ext_list="
if exist "!TMPEXTS!" (
    for /f "usebackq tokens=*" %%L in ("!TMPEXTS!") do (
        set "e=%%L"
        set "e=!e: =!"
        if not "!e!"=="" (
            echo !ext_list! | findstr /i "!e!" >nul 2>&1
            if !errorlevel!==1 set "ext_list=!ext_list!!e! "
        )
    )
    del "!TMPEXTS!"
)

:: Step 3 — check if any expected extension is present
set "has_expected=0"
set "good_exts="
set "bad_exts="

if "!CE!"=="*" (
    set "has_expected=1"
    set "good_exts=!ext_list!"
) else (
    for %%E in (!CE!) do (
        echo !ext_list! | findstr /i "\.%%E" >nul 2>&1
        if !errorlevel!==0 (
            set "has_expected=1"
            set "good_exts=!good_exts!.%%E "
        )
    )
    for %%E in (!CE!) do (
        echo !ext_list! | findstr /i "\.%%E" >nul 2>&1
        if !errorlevel!==1 (
            echo !ext_list! | findstr /i "[a-z]" >nul 2>&1
        )
    )
    set "bad_exts=!ext_list!"
    for %%E in (!CE!) do set "bad_exts=!bad_exts:.%%E =!"
    set "bad_exts=!bad_exts: =!"
)

if !has_expected!==1 (
    if "!bad_exts!"=="" (
        call :wr "  [OK]         !CN! (!file_count! files |!good_exts!)"
    ) else (
        call :wr "  [OK+ALERT]   !CN! (!file_count! files | expected:!good_exts!| also found: !bad_exts!)"
    )
    set /a present+=1
) else (
    call :wr "  [ALERT]      !CN! - !file_count! files, none match expected (!CE!) | found: !ext_list!"
    set /a alerts+=1
)
exit /b


:: ════════════════════════════════════════════════════════════════════════
:wr
echo %~1
echo %~1>> "!REPORT!"
exit /b

:wrb
echo.
echo.>> "!REPORT!"
exit /b
