import java.util.Properties
import java.io.FileInputStream



plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.stockarchery.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.stockarchery.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            // R8 is left off. It was once suspected of breaking Firebase Auth's
            // saved session, but that was NOT the cause (see the firebase-auth
            // pin below). Turning R8 back on to shrink the APK is a separate
            // change that needs its own testing.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// firebase_core 3.15.2 pulls in Firebase Android BoM 33.16.0, which contains
// firebase-auth 23.2.1. From 23.2.1 the SDK encrypts its saved login with an
// Android Keystore key; on some phones that key cannot be loaded ("Keystore
// cannot load the key ... firebear_main_key_id_for_storage_crypto"), so the
// session is never persisted and the user is logged out on every cold start
// (firebase-android-sdk #7111, #8064; still reported on 24.0.1).
// 23.2.0 predates that encryption. Pin ONLY firebase-auth to it; everything
// else stays on the BoM. Remove this once a fixed firebase-auth is confirmed.
configurations.all {
    resolutionStrategy.force("com.google.firebase:firebase-auth:23.2.0")
}

flutter {
    source = "../.."
}
