import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}
val isFdroidBuild = (System.getenv("FDROID_BUILD") ?: "false").equals("true", ignoreCase = true)

android {
    namespace = "org.t2decode.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "org.t2decode.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyPropertiesFile.exists()) {
            create("release") {
                keyAlias     = keyProperties["keyAlias"].toString()
                keyPassword  = keyProperties["keyPassword"].toString()
                storeFile    = file(keyProperties["storeFile"].toString())
                storePassword = keyProperties["storePassword"].toString()
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isDebuggable  = true
        }
        release {
            if (keyPropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else if (!isFdroidBuild) {
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

configurations.all {
    exclude(group = "com.google.android.play")
    exclude(group = "com.google.android.play", module = "core")
    exclude(group = "com.google.android.play", module = "core-common")
    exclude(group = "com.google.android.play", module = "feature-delivery")
    exclude(group = "com.google.android.play", module = "app-update")
    exclude(group = "com.google.android.play", module = "review")
}

flutter {
    source = "../.."
}
