plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.personal_finance_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // --- අලුත් කොටස 1: Desugaring සක්‍රිය කිරීම ---
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.example.personal_finance_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// --- අලුත් කොටස 2: Desugaring සඳහා අවශ්‍ය Library එක ලබා දීම ---
dependencies {
    // 2.0.4 වෙනුවට 2.1.4 ලෙස වෙනස් කර ඇත
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}