@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title CDC Moscardo - publicar datos
echo.
echo   CDC Moscardo . publicar datos
echo   Carpeta: %CD%
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo   ERROR: no encuentro git en este ordenador.
  echo   Instalalo desde https://git-scm.com/downloads
  goto :fin
)

set "PY="
py -3 --version >nul 2>&1 && set "PY=py -3"
if not defined PY ( python --version >nul 2>&1 && set "PY=python" )
if not defined PY ( python3 --version >nul 2>&1 && set "PY=python3" )

if defined PY (
  echo   Usando !PY!
  echo.
  !PY! publicar.py --auto
  goto :fin
)

echo   No hay Python instalado. Voy por la via corta, solo con git.
echo   (Asi no se comprueba que el JSON sea valido.)
echo.

set "NUEVO="
for %%D in ("%USERPROFILE%\Downloads" "%USERPROFILE%\Descargas") do (
  if exist "%%~D" (
    for /f "delims=" %%F in ('dir /b /a-d /o-d "%%~D\datos*.json" 2^>nul') do (
      if not defined NUEVO set "NUEVO=%%~D\%%F"
    )
  )
)

if defined NUEVO (
  echo   Copiando "!NUEVO!"
  copy /y "!NUEVO!" "datos.json" >nul
) else (
  echo   No hay ningun datos.json nuevo en Descargas.
  echo   Subo lo que ya haya en la carpeta.
)

echo.
git add -A
git commit -m "Actualiza datos"
echo.
echo   Subiendo a GitHub...
git push

:fin
echo.
echo   ------------------------------------------------
echo   Terminado. Lee los mensajes de arriba.
echo   ------------------------------------------------
echo.
pause
