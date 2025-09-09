@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ========== CONFIG EDITABLE ==========
set "REPO_SLUG=AlexPraxedes12/LearnSynth"
set "GH_TAG=models-v1"
set "GH_RELEASE_TITLE=Models v1"
set "GH_RELEASE_NOTES=Initial GGUF models for LearnSynth"

set "HF_USER=AlexMelodexa"        REM <-- CAMBIA ESTO
set "HF_REPO=LearnSynth-Models"    REM <-- CAMBIA ESTO
set "HF_TOKEN=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"                    REM <-- Opcional: pega tu token HF aquí (quitará prompts). Dejar vacío para ser solicitado al hacer push.

set "SRC_DIR=C:\dev-projects\LearnSynth\learnsynth_offline_llm\assets\models"
set "HF_WORK_DIR=%USERPROFILE%\hf_upload\%HF_REPO%"
REM ====================================

echo:
echo [STEP] Checando dependencias...
where gh >nul 2>&1 || (echo [ERROR] GitHub CLI 'gh' no encontrado. Instala GH CLI. & exit /b 1)
where git >nul 2>&1 || (echo [ERROR] Git no encontrado. Instala Git. & exit /b 1)
git lfs --version >nul 2>&1 || (echo [ERROR] Git LFS no encontrado. Instala Git LFS. & exit /b 1)

if not exist "%SRC_DIR%" (
  echo [ERROR] No existe la carpeta de modelos: "%SRC_DIR%"
  exit /b 1
)

for /f %%C in ('dir /b "%SRC_DIR%\*.gguf" ^| find /v /c ""') do set COUNT=%%C
if "x!COUNT!"=="x0" (
  echo [ERROR] No hay archivos .gguf en: "%SRC_DIR%"
  exit /b 1
)

echo:
echo [STEP] Autenticacion GH...
gh auth status >nul 2>&1 || (
  echo [ERROR] No estas autenticado en GitHub CLI.
  echo Ejecuta: gh auth login
  exit /b 1
)

echo:
echo [STEP] Creando/Asegurando release "%GH_TAG%" en "%REPO_SLUG%"...
gh release view "%GH_TAG%" -R "%REPO_SLUG%" >nul 2>&1
if errorlevel 1 (
  gh release create "%GH_TAG%" -R "%REPO_SLUG%" -t "%GH_RELEASE_TITLE%" -n "%GH_RELEASE_NOTES%" --latest || (echo [ERROR] No se pudo crear el release. & exit /b 1)
) else (
  echo [INFO] Release ya existe, se reutilizara.
)

echo:
echo [STEP] Calculando SHA256 y subiendo modelos a GitHub Releases...
pushd "%SRC_DIR%" >nul

del /q "sha256sum.txt" 2>nul
for %%F in (*.gguf) do (
  for /f "usebackq tokens=1" %%H in (`powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 '%%F' ^| %% { $_.Hash.ToLower() }"`) do (
    echo %%H *%%F>> "sha256sum.txt"
  )
)

for %%F in (*.gguf) do (
  echo   [+] %%F
  gh release upload "%GH_TAG%" "%%F" --repo "%REPO_SLUG%" --clobber || (echo [ERROR] Fallo al subir %%F a GH. & popd & exit /b 1)
)

echo [STEP] Subiendo sha256sum.txt a GH...
gh release upload "%GH_TAG%" "sha256sum.txt" --repo "%REPO_SLUG%" --clobber || (echo [WARN] No se pudo subir sha256sum.txt a GH.)

popd >nul

REM ----------------- HUGGING FACE -----------------
echo:
echo [STEP] Preparando repo de Hugging Face...
if not exist "%HF_WORK_DIR%" (
  mkdir "%HF_WORK_DIR%" >nul 2>&1
  if errorlevel 1 (echo [ERROR] No se pudo crear "%HF_WORK_DIR%". & exit /b 1)
  echo [INFO] Clonando https://huggingface.co/%HF_USER%/%HF_REPO%
  git clone "https://huggingface.co/%HF_USER%/%HF_REPO%" "%HF_WORK_DIR%" || (
    echo [ERROR] No se pudo clonar el repo HF. Verifica que exista y sea publico.
    exit /b 1
  )
) else (
  echo [INFO] Usando carpeta local HF: "%HF_WORK_DIR%"
)

pushd "%HF_WORK_DIR%" >nul

REM Si hay token configurado, usarlo en la URL del remoto para push sin prompt
if not "x%HF_TOKEN%"=="x" (
  git remote set-url origin "https://%HF_USER%:%HF_TOKEN%@huggingface.co/%HF_USER%/%HF_REPO%"
)

git fetch origin >nul 2>&1
git checkout main >nul 2>&1 || git checkout -b main >nul 2>&1
git pull --rebase origin main >nul 2>&1

git lfs install >nul
git lfs track "*.gguf" >nul
if not exist ".gitattributes" echo *.gguf filter=lfs diff=lfs merge=lfs -text> .gitattributes

echo:
echo [STEP] Copiando .gguf al repo HF...
copy /Y "%SRC_DIR%\*.gguf" ".\" >nul

echo:
echo [STEP] Generando sha256sum.txt y manifest.json (con mirrors GH + HF)...
for /f "tokens=*" %%A in ('powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $files=Get-ChildItem -File -Filter *.gguf; if(-not $files){exit 1}; $sum=@(); $arr=@(); $ghBase='https://github.com/%REPO_SLUG%/releases/download/%GH_TAG%'; $hfBase='https://huggingface.co/%HF_USER%/%HF_REPO%/resolve/main'; foreach($f in $files){ $h=(Get-FileHash -Algorithm SHA256 $f.FullName).Hash.ToLower(); $sum+=($h+' *'+$f.Name); $arr+=[pscustomobject]@{ id=$f.BaseName.ToLower(); name=$f.Name; size_bytes=$f.Length; sha256=$h; mirrors=@($ghBase+'/'+$f.Name, $hfBase+'/'+$f.Name) } }; $sum ^| Set-Content -Encoding ascii sha256sum.txt; @{version=1; models=$arr} ^| ConvertTo-Json -Depth 6 ^| Set-Content -Encoding utf8 manifest.json; Write-Output OK"') do set "PSOK=%%A"

if /i not "%PSOK%"=="OK" (
  echo [ERROR] PowerShell fallo generando hashes/manifest.
  popd & exit /b 1
)

git add .gitattributes *.gguf sha256sum.txt manifest.json >nul
git commit -m "Add/Update GGUF models + checksums + manifest" >nul 2>&1

echo:
echo [STEP] Haciendo push al repo HF...
git push origin main || (
  echo [ERROR] git push fallo. Si no seteaste HF_TOKEN, te pedira USER y PASSWORD (usa tu token).
  popd & exit /b 1
)

popd >nul

REM --------- (Opcional) Subir manifest.json tambien a GH Release ----------
echo:
echo [STEP] Subiendo manifest.json a GitHub Release (opcional)...
gh release upload "%GH_TAG%" "%HF_WORK_DIR%\manifest.json" --repo "%REPO_SLUG%" --clobber >nul 2>&1

echo:
echo [DONE] ¡Todo listo!
echo.
echo  Manifest (HF): https://huggingface.co/%HF_USER%/%HF_REPO%/resolve/main/manifest.json
echo  Ejemplo GH:    https://github.com/%REPO_SLUG%/releases/download/%GH_TAG%/NOMBRE_DEL_MODELO.gguf
echo  Ejemplo HF:    https://huggingface.co/%HF_USER%/%HF_REPO%/resolve/main/NOMBRE_DEL_MODELO.gguf
echo.
echo  Archivos fuente: "%SRC_DIR%"
echo  Carpeta repo HF local: "%HF_WORK_DIR%"
endlocal
