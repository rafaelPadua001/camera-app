#mantem todas as classes do TensorFlow lite GPU
-keep class org.tensorFlow.lite.gpu.**{*;}
-keep class org.tensorFlow.lite.nnapi.**{*;}
-keep class org.tensorFlow.lite.**{*;}
-keep class org.tensorFlow.lite.**{*;}
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }

#Mantem classes do Google Play Core Library
-keep class com.google.android.play.**{*;}

#Evita a remoção de anotações
-keepattributes *Annotation*
-dontwarn org.tensorflow.**

#mantem classes do flutter que podem esta sendo exlcuidas
-keep class io.flutter.embedding.engine.deferredcomponentes.**{*;}

# Evitar remoção de classes importantes para atualizção de componentes dinamicos
-keep class com.google.play.core.splitinstall.**{*;}
-keep class com.google.play.core.tasks.**{*;}
-keep class com.google.play.core.splitcompat.**{*;}

#mantem o splitCompatApplication necessário para flutter
-keep class io.flutter.app.FlutterPlayStoreSplitApplication {*;}

# mantem classes utilizadas por reflexão
-keep class * {@com.google.gson.annotations.serializedName *;}
