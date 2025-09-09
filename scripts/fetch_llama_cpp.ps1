Param(
  [string]$RepoUrl = "https://github.com/ggerganov/llama.cpp.git",
  [string]$BranchOrTag = "master"
)
$ErrorActionPreference = "Stop"
$dest = Join-Path $PSScriptRoot "..\learnsynth_offline_llm\android\src\main\cpp\third_party\llama.cpp"
$dest = (Resolve-Path $dest).Path

if (!(Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }

# Si ya hay un .git, solo actualizar
if (Test-Path (Join-Path $dest ".git")) {
  Write-Host "Updating existing llama.cpp in $dest"
  git -C $dest fetch --depth 1 origin $BranchOrTag
  git -C $dest checkout -f FETCH_HEAD
} else {
  # Clonado superficial (solo el arbol actual)
  Write-Host "Cloning llama.cpp into $dest"
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  git clone --depth 1 --branch $BranchOrTag $RepoUrl $dest
}

# Sanidad: verificar carpetas clave
$must = @("src","ggml\src")
foreach ($m in $must) {
  $p = Join-Path $dest $m
  if (!(Test-Path $p)) {
    throw "Missing required directory: $p . Repo layout unexpected."
  }
}
Write-Host "llama.cpp fetched OK at $dest"
