<# ================================================
  LearnSynth - MSIX installer helper
  - Import PFX, export CER, install CER to trusted stores
  - Verify MSIX signature and launch installer
  Requisitos:
    - Windows SDK (para signtool.exe)
    - PFX existente (self-signed o de CA)
  Uso:
    powershell -ExecutionPolicy Bypass -File tools\install_msix_with_cert.ps1
================================================ #>

param(
  # === Ajusta estas rutas según tu proyecto ===
  [string]$PfxPath = "certs\codesign-test.pfx",
  [string]$PfxPassword = "P@ssw0rd!",
  [string]$CertOutPath = "certs\codesign-test.cer",
  [string]$MsixPath = "build\installer\msix\learnsynth.msix",

  # Opcional: Subject/CN para localizar el cert si hay varios importados
  [string]$CertSubjectLike = "LearnSynth"   # coincide con parte del CN (ej: 'LearnSynth Test Publisher')
)

$ErrorActionPreference = "Stop"

function Write-Info($m){ Write-Host "[+] $m" -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host "[!] $m" -ForegroundColor Yellow }
function Write-Err ($m){ Write-Host "[X] $m" -ForegroundColor Red }

# --- 0) Checks básicos
if (!(Test-Path $PfxPath)) { Write-Err "No se encontró el PFX en: $PfxPath"; exit 1 }
if (!(Test-Path $MsixPath)) { Write-Err "No se encontró el MSIX en: $MsixPath"; exit 1 }

# --- 1) Importar PFX al almacén del usuario
Write-Info "Importando PFX al almacén del usuario (CurrentUser\My)..."
$securePwd = ConvertTo-SecureString -AsPlainText -Force $PfxPassword
Import-PfxCertificate -FilePath $PfxPath -Password $securePwd -CertStoreLocation "Cert:\CurrentUser\My" | Out-Null

# --- 2) Localizar el certificado por Subject
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*$CertSubjectLike*" } | Select-Object -First 1
if (-not $cert) { Write-Err "No se encontró un certificado en CurrentUser\My cuyo Subject contenga: $CertSubjectLike"; exit 1 }

Write-Info ("Certificado encontrado: Subject='{0}'  Thumbprint={1}" -f $cert.Subject, $cert.Thumbprint)

# --- 3) Exportar CER (clave pública)
$certDir = Split-Path -Parent $CertOutPath
if ($certDir -and !(Test-Path $certDir)) { New-Item -ItemType Directory -Path $certDir | Out-Null }
Write-Info "Exportando .cer: $CertOutPath"
Export-Certificate -Cert $cert.PSPath -FilePath $CertOutPath | Out-Null

# --- 4) Instalar CER en TrustedPeople y Root (usuario actual)
Write-Info "Instalando CER en TrustedPeople (usuario actual)..."
Import-Certificate -FilePath $CertOutPath -CertStoreLocation "Cert:\CurrentUser\TrustedPeople" | Out-Null

Write-Info "Instalando CER en Root (usuario actual)..."
Import-Certificate -FilePath $CertOutPath -CertStoreLocation "Cert:\CurrentUser\Root" | Out-Null

# --- 5) Encontrar SignTool.exe (Windows SDK) automáticamente
function Find-SignTool {
  $candidates = @(
    "$Env:ProgramFiles(x86)\Windows Kits\10\bin\*\x64\signtool.exe",
    "$Env:ProgramFiles(x86)\Windows Kits\10\bin\*\x86\signtool.exe"
  )
  $paths = @()
  foreach ($pat in $candidates) { $paths += Get-ChildItem -Path $pat -ErrorAction SilentlyContinue }
  if ($paths.Count -eq 0) { return $null }
  # Toma la versión "más nueva" por carpeta
  return ($paths | Sort-Object FullName -Descending | Select-Object -First 1).FullName
}

$signtool = Find-SignTool
if (-not $signtool) {
  Write-Warn "No se encontró signtool.exe automáticamente. Si tienes el Windows SDK instalado, especifica la ruta manualmente."
} else {
  Write-Info "SignTool: $signtool"
  # --- 6) Verificar firma del MSIX
  Write-Info "Verificando la firma del MSIX..."
  & $signtool verify /pa /v "$MsixPath"
}

# --- 7) Abrir instalador MSIX
Write-Info "Abriendo el instalador MSIX..."
Start-Process -FilePath "$MsixPath"

Write-Host "`nTodo listo. Si aún ves 'Editor desconocido', verifica que en tu pubspec.yaml (msix_config.publisher) el CN coincida con el Subject del cert:`n  $($cert.Subject)" -ForegroundColor Green
