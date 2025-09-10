# learns

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Build

```bash
# Online-only builds (public submission)
flutter build web --release \
  --dart-define=API_BASE=https://your-api.fly.dev \
  --dart-define=ENABLE_OFFLINE_LLM=false

flutter build windows --release ^
  --dart-define=API_BASE=https://your-api.fly.dev ^
  --dart-define=ENABLE_OFFLINE_LLM=false

flutter build apk --release \
  --dart-define=API_BASE=https://your-api.fly.dev \
  --dart-define=ENABLE_OFFLINE_LLM=false

# To test the offline path locally:
flutter run --dart-define=API_BASE=http://localhost:8000 \
            --dart-define=ENABLE_OFFLINE_LLM=true
```
