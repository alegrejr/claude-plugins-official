@echo off
setlocal enabledelayedexpansion

set "DOWNLOADS=%USERPROFILE%\Downloads"
if not "%~1"=="" set "DOWNLOADS=%~1"

if not exist "%DOWNLOADS%" (
    echo No se encontro la carpeta: %DOWNLOADS%
    exit /b 1
)

set moved=0
set skipped=0

for %%F in ("%DOWNLOADS%\*.*") do (
    set "filename=%%~nxF"
    set "ext=%%~xF"

    if "!ext!"=="" (
        set /a skipped+=1
    ) else (
        set "ext=!ext:~1!"
        call :tolower ext

        set "dest="

        for %%E in (jpg jpeg png gif bmp svg webp ico tiff) do if /i "!ext!"=="%%E" set "dest=Imagenes"
        for %%E in (mp4 mkv avi mov wmv flv webm m4v) do if /i "!ext!"=="%%E" set "dest=Videos"
        for %%E in (mp3 wav flac aac ogg m4a wma) do if /i "!ext!"=="%%E" set "dest=Audio"
        for %%E in (pdf doc docx txt odt rtf md) do if /i "!ext!"=="%%E" set "dest=Documentos"
        for %%E in (xls xlsx csv ods) do if /i "!ext!"=="%%E" set "dest=Hojas_de_Calculo"
        for %%E in (ppt pptx odp) do if /i "!ext!"=="%%E" set "dest=Presentaciones"
        for %%E in (zip tar gz rar 7z bz2 xz) do if /i "!ext!"=="%%E" set "dest=Comprimidos"
        for %%E in (exe msi dmg pkg deb rpm) do if /i "!ext!"=="%%E" set "dest=Instaladores"
        for %%E in (py js ts html css json xml yaml yml sh java c cpp h) do if /i "!ext!"=="%%E" set "dest=Codigo"
        for %%E in (torrent) do if /i "!ext!"=="%%E" set "dest=Torrents"

        if "!dest!"=="" set "dest=Otros"

        set "destpath=%DOWNLOADS%\!dest!"
        if not exist "!destpath!" mkdir "!destpath!"

        if exist "!destpath!\!filename!" (
            set "newname=%%~nF_%time:~0,2%%time:~3,2%%time:~6,2%.!ext!"
            set "newname=!newname: =0!"
            move "%%F" "!destpath!\!newname!" >nul
            echo   !filename! -^> !dest!\!newname!
        ) else (
            move "%%F" "!destpath!\!filename!" >nul
            echo   !filename! -^> !dest!\
        )
        set /a moved+=1
    )
)

echo.
echo Listo: %moved% archivos organizados, %skipped% sin extension ignorados.
pause
exit /b 0

:tolower
for %%A in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    set "%1=!%1:%%A=%%A!"
)
exit /b
