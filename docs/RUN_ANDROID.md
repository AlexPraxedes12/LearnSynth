Run on Android

Requisitos:

Android NDK 27, SDK 34, dispositivo ARM64

ADB en PATH

Pasos:

.\clean.ps1

Copia el modelo:
.\push_model.ps1 -ModelPath "C:\modelos\tinyllama-1.1b.Q4_K_M.gguf" -Package "com.example.learns"

flutter run -d <DEVICE_ID>

Notas:

Los modelos se copian a /sdcard/Android/data/<package>/files/models/.

El plugin lee rutas desde Dart (pasadas a JNI) y no descarga modelos.
