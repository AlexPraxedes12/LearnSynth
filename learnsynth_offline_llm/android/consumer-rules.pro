-keep class com.learnsynth.learnsynth_offline_llm.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
