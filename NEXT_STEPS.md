Next steps (Android plugin)

Verificación rápida:

Conectar dispositivo ARM64, ejecutar .\clean.ps1, luego flutter run -d <ID>.

En la app de ejemplo pulsa Load model, Generate.

Artefactos:

Este módulo expone JNI para tiny LLM (llama.cpp).

Usa consumer-rules.pro para evitar ofuscado de JNI/bridge.

Scripts:

clean.ps1: limpia Flutter y artefactos nativos.

push_model.ps1 -ModelPath "<ruta.gguf>" [-Package "com.example.learns"]: copia modelo al sandbox de la app.
