@echo off
setlocal

REM Cambia esta ruta si tu proyecto no está en el mismo directorio que este .bat
cd /d "%~dp0"

echo === LIMPIANDO pubspec.lock, .dart_tool y .gradle...
del pubspec.lock 2>nul
rmdir /s /q .dart_tool
rmdir /s /q android\.gradle

echo === BORRANDO CACHÉ LOCAL DE file_picker...
set CACHE_DIR=%USERPROFILE%\AppData\Local\Pub\Cache\hosted\pub.dev

for /d %%F in ("%CACHE_DIR%\file_picker-*") do (
    echo Borrando %%~nxF
    rmdir /s /q "%%F"
)

echo === REINSTALANDO DEPENDENCIAS...
flutter pub get

echo === LIMPIANDO Y RECONSTRUYENDO...
flutter clean
flutter run

echo === PROCESO COMPLETADO ===
pause
