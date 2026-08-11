# ONNX Runtime looks its Java classes up from native code with FindClass /
# GetMethodID, by literal name. R8 renames them, the lookup returns null, and
# the process dies with:
#
#   JNI DETECTED ERROR IN APPLICATION: java_class == null
#     at art::JNI<false>::GetMethodID
#     from convertToTensorInfo -> Java_ai_onnxruntime_OrtSession_run
#
# It is a hard SIGABRT in native code, so nothing in Dart can catch it: the app
# vanishes the moment the codec touches the model. Keep the whole package —
# these are the types the native layer reflects on to build tensors and read
# results back.
-keep class ai.onnxruntime.** { *; }
-keepclassmembers class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# The Flutter plugin's platform-channel handler, reached the same way.
-keep class com.masicai.flutteronnxruntime.** { *; }
-dontwarn com.masicai.flutteronnxruntime.**
