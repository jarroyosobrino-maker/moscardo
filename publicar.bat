@echo off
REM Windows: doble clic para publicar el datos.json mas reciente de Descargas.
cd /d "%~dp0"
python publicar.py --auto
