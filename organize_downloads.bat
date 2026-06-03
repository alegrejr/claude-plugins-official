@echo off
setlocal enabledelayedexpansion

set "DOWNLOADS=%USERPROFILE%\Downloads"
if not "%~1"=="" set "DOWNLOADS=%~1"

if not exist "%DOWNLOADS%" (
    echo Folder not found: %DOWNLOADS%
    exit /b 1
)

set moved=0
set folders_moved=0

:: ─── ORGANIZAR ARCHIVOS SUELTOS ───────────────────────────────────────────────
for %%F in ("%DOWNLOADS%\*.*") do (
    set "filename=%%~nxF"
    set "ext=%%~xF"
    if not "!ext!"=="" (
        set "ext=!ext:~1!"
        call :tolower ext
        call :get_category "!ext!" dest

        set "destpath=%DOWNLOADS%\!dest!"
        if not exist "!destpath!" mkdir "!destpath!"

        if exist "!destpath!\!filename!" (
            set "ts=%time:~0,2%%time:~3,2%%time:~6,2%"
            set "ts=!ts: =0!"
            move "%%F" "!destpath!\%%~nF_!ts!.!ext!" >nul
        ) else (
            move "%%F" "!destpath!\!filename!" >nul
        )
        echo   [FILE] !filename! -^> !dest!\
        set /a moved+=1
    )
)

:: ─── ORGANIZAR SUBCARPETAS POR CONTENIDO (80%%) ───────────────────────────────
for /d %%D in ("%DOWNLOADS%\*") do (
    set "dirname=%%~nxD"

    :: Saltar las carpetas de destino que ya creamos
    set "is_dest=0"
    for %%C in (Images Videos Audio Documents Spreadsheets Presentations Compressed Installers Code Torrents Others) do (
        if /i "!dirname!"=="%%C" set "is_dest=1"
    )
    if "!is_dest!"=="0" (
        call :analyze_folder "%%D" dominant_cat dominant_pct
        if !dominant_pct! geq 80 (
            set "destpath=%DOWNLOADS%\!dominant_cat!"
            if not exist "!destpath!" mkdir "!destpath!"
            move "%%D" "!destpath!\!dirname!" >nul
            echo   [FOLDER] !dirname! (!dominant_pct!%% !dominant_cat!) -^> !dominant_cat!\
            set /a folders_moved+=1
        ) else (
            echo   [FOLDER] !dirname! - mixed content, left in place
        )
    )
)

echo.
echo Done: %moved% files and %folders_moved% folders organized.
pause
exit /b 0


:: ─── SUBROUTINE: get category from extension ─────────────────────────────────
:get_category
set "e=%~1"
set "%~2=Others"
for %%E in (jpg jpeg png gif bmp svg webp ico tiff) do if /i "%e%"=="%%E" ( set "%~2=Images" & exit /b )
for %%E in (mp4 mkv avi mov wmv flv webm m4v) do if /i "%e%"=="%%E" ( set "%~2=Videos" & exit /b )
for %%E in (mp3 wav flac aac ogg m4a wma) do if /i "%e%"=="%%E" ( set "%~2=Audio" & exit /b )
for %%E in (pdf doc docx txt odt rtf md) do if /i "%e%"=="%%E" ( set "%~2=Documents" & exit /b )
for %%E in (xls xlsx csv ods) do if /i "%e%"=="%%E" ( set "%~2=Spreadsheets" & exit /b )
for %%E in (ppt pptx odp) do if /i "%e%"=="%%E" ( set "%~2=Presentations" & exit /b )
for %%E in (zip tar gz rar 7z bz2 xz) do if /i "%e%"=="%%E" ( set "%~2=Compressed" & exit /b )
for %%E in (exe msi dmg pkg deb rpm) do if /i "%e%"=="%%E" ( set "%~2=Installers" & exit /b )
for %%E in (py js ts html css json xml yaml yml sh java c cpp h) do if /i "%e%"=="%%E" ( set "%~2=Code" & exit /b )
for %%E in (torrent) do if /i "%e%"=="%%E" ( set "%~2=Torrents" & exit /b )
exit /b


:: ─── SUBROUTINE: analyze folder content ──────────────────────────────────────
:analyze_folder
set "folder=%~1"
set "total=0"
set "c_Images=0"
set "c_Videos=0"
set "c_Audio=0"
set "c_Documents=0"
set "c_Spreadsheets=0"
set "c_Presentations=0"
set "c_Compressed=0"
set "c_Installers=0"
set "c_Code=0"

for /r "%folder%" %%F in (*.*) do (
    set "fext=%%~xF"
    if not "!fext!"=="" (
        set "fext=!fext:~1!"
        call :tolower fext
        call :get_category "!fext!" fcat
        set /a c_!fcat!+=1
        set /a total+=1
    )
)

if %total%==0 ( set "%~2=Others" & set "%~3=0" & exit /b )

:: Find dominant category
set "best_cat=Others"
set "best_count=0"
for %%C in (Images Videos Audio Documents Spreadsheets Presentations Compressed Installers Code) do (
    if !c_%%C! gtr !best_count! (
        set "best_count=!c_%%C!"
        set "best_cat=%%C"
    )
)

set /a pct=best_count*100/total
set "%~2=!best_cat!"
set "%~3=!pct!"
exit /b


:: ─── SUBROUTINE: lowercase ───────────────────────────────────────────────────
:tolower
for %%A in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do set "%1=!%1:%%A=%%A!"
exit /b
