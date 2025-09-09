@echo off
setlocal
set "HF_USER=AlexMelodexa"
set "HF_REPO=LearnSynth-Models"
set "SRC_DIR=C:\dev-projects\LearnSynth\learnsynth_offline_llm\assets\models"
set "HF_DIR=%USERPROFILE%\hf_upload\%HF_REPO%"

where git >nul 2>&1 || (echo [ERROR] Falta Git & exit /b 1)
git lfs --version >nul 2>&1 || (echo [ERROR] Falta Git LFS & exit /b 1)

if not exist "%HF_DIR%\.git" (
  mkdir "%HF_DIR%" 2>nul
  git clone "https://huggingface.co/%HF_USER%/%HF_REPO%" "%HF_DIR%" || (echo [ERROR] Clone HF fallo & exit /b 1)
)

copy /Y "%SRC_DIR%\*.gguf" "%HF_DIR%" || (echo [ERROR] No pude copiar .gguf & exit /b 1)

pushd "%HF_DIR%"
git lfs install
git lfs track "*.gguf"
if not exist ".gitattributes" echo *.gguf filter=lfs diff=lfs merge=lfs -text> .gitattributes
git add .gitattributes *.gguf

powershell -NoProfile -Command ^
  "Get-ChildItem -File *.gguf | ForEach-Object { (Get-FileHash -Algorithm SHA256 $_.FullName).Hash.ToLower() + ' *' + $_.Name } | Set-Content -Encoding ascii .\sha256sum.txt"
powershell -NoProfile -Command ^
  "$files=Get-ChildItem -File *.gguf; $arr=@(); $gh='https://github.com/AlexPraxedes12/LearnSynth/releases/download/models-v1'; $hf='https://huggingface.co/%HF_USER%/%HF_REPO%/resolve/main'; foreach($f in $files){ $h=(Get-FileHash -Algorithm SHA256 $f.FullName).Hash.ToLower(); $arr+=[pscustomobject]@{ id=$f.BaseName.ToLower(); name=$f.Name; size_bytes=$f.Length; sha256=$h; mirrors=@($gh+'/'+$f.Name, $hf+'/'+$f.Name) } }; @{version=1; models=$arr} | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 .\manifest.json"

git add sha256sum.txt manifest.json
git commit -m "Add GGUF models + checksums + manifest"
git push
popd
endlocal
