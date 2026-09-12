# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ByteMeter Native Models and Services
-keep class com.bytemeter.network.services.** { *; }
-keep class com.bytemeter.network.stats.** { *; }
-keep class com.bytemeter.network.bridge.** { *; }
-keep class com.bytemeter.network.crypto.** { *; }

# Kotlin Coroutines
-keepclassmembers class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# AndroidX
-dontwarn androidx.**
