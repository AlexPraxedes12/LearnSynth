param(
[Parameter(Mandatory=$true)][string]$ModelPath,
[string]$Package = "com.example.learns"
)

if (!(Test-Path $ModelPath)) { Write-Error "Modelo no encontrado: $ModelPath"; exit 1 }
$dev = (adb devices | Select-String "device$").ToString().Split("`t")[0]
if (-not $dev) { Write-Error "No hay dispositivo ADB"; exit 1 }

$dst = "/sdcard/Android/data/$Package/files/models/"
adb -s $dev shell "mkdir -p $dst" | Out-Null
adb -s $dev push "$ModelPath" "$dst" | Out-Null

Write-Host "Modelo copiado a $dst"
