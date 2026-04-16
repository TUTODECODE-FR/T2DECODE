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
    namespace = "com.tutodecode.app"
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
        applicationId = "com.tutodecode.app"
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
            // For troubleshooting, let's disable minification temporarily
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
