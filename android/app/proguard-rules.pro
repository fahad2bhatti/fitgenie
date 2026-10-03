# ---- Flutter ----
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ---- Firebase / Google Play services ----
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.fitness.** { *; }
-keep class ** extends com.google.protobuf.GeneratedMessageLite { *; }

# ---- Attributes (Signature is REQUIRED for Gson TypeToken under R8) ----
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# ---- flutter_local_notifications (Gson TypeToken fix) ----
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# ---- Flutter deferred components (Play Feature Delivery) ----
# Not used in this app, safe to ignore since Play Core split-install
# classes aren't a real dependency.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task