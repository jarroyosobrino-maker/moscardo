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

REM ---- Buscar el datos.json mas reciente en Descargas ----
set "NUEVO="
for %%D in ("%USERPROFILE%\Downloads" "%USERPROFILE%\Descargas") do (
  if exist "%%~D" (
    for /f "delims=" %%F in ('dir /b /a-d /o-d "%%~D\datos*.json" 2^>nul') do (
      if not defined NUEVO set "NUEVO=%%~D\%%F"
    )
  )
)

if not defined NUEVO (
  echo   No hay ningun datos.json nuevo en Descargas.
  echo   Subo lo que ya haya en la carpeta.
  goto :subir
)

echo   Encontrado: "!NUEVO!"
echo   Comprobando que el fichero es correcto...

REM ---- Validar el JSON con PowerShell antes de tocar nada ----
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "try {" ^
  "  $d = Get-Content -Raw -Encoding UTF8 '!NUEVO!' | ConvertFrom-Json;" ^
  "  if (-not $d.partidos)      { Write-Host '   FALLO: no tiene la lista partidos.'; exit 1 }" ^
  "  if (-not $d.clasificacion) { Write-Host '   FALLO: no tiene la lista clasificacion.'; exit 1 }" ^
  "  $np = @($d.partidos).Count; $nc = @($d.clasificacion).Count;" ^
  "  $jug = @($d.partidos ^| Where-Object { $_.gf -ne $null }).Count;" ^
  "  Write-Host \"   OK: $np partidos, $nc equipos, $jug jornadas disputadas.\";" ^
  "  if ($np -ne 34) { Write-Host '   AVISO: no hay 34 partidos. Revisalo.' }" ^
  "  if ($nc -ne 18) { Write-Host '   AVISO: no hay 18 equipos. Revisalo.' }" ^
  "  exit 0" ^
  "} catch { Write-Host ('   FALLO: el fichero no es JSON valido. ' + $_.Exception.Message); exit 1 }"

if errorlevel 1 (
  echo.
  echo   No subo nada, para no dejar la web rota.
  echo   Vuelve a descargar el fichero y pruebalo otra vez.
  goto :fin
)

if exist "datos.json" copy /y "datos.json" "datos.json.anterior" >nul
copy /y "!NUEVO!" "datos.json" >nul
echo   datos.json sustituido. Copia del anterior en datos.json.anterior

:subir
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
