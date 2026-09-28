# Flutter's embedding references Play Core from unused deferred-component
# classes. The library is not a dependency of this app, and F-Droid rejects
# any com.google.android.play type left in the dex.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
