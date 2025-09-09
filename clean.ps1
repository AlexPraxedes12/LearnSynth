# Limpia Flutter y artefactos nativos del plugin
flutter clean

# Borra carpetas con Remove-Item en PowerShell (no uses `/q` ni `rd`)
$paths = @(
  "./build",
  "./learnsynth_offline_llm/build",
  "./learnsynth_offline_llm/android/.cxx"
)
foreach ($p in $paths) {
  if (Test-Path $p) { Remove-Item -Recurse -Force $p }
}

# Vuelve a resolver dependencias
flutter pub get
