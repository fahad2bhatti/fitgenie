plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fitgenie.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.fitgenie.app"
        // Chahe to yahan direct 23 likh sakta hai:
        // minSdk = 23
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // 🔐 DIRECT SIGNING CONFIG — NO Properties
    signingConfigs {
        create("release") {
            // Yahan apna upload-keystore.jks ka path, jo already ban chuka hai:
            storeFile = file("upload-keystore.jks")

            // 👇 Yahan WAHI password daal jo tu ne keystore banate waqt diya tha
            storePassword = "Fitgenie@0185"
            keyAlias = "upload"
            keyPassword = "Fitgenie@0185"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")

            // R8 issues avoid karne ke liye:
            isMinifyEnabled = false
            isShrinkResources = false

            // ProGuard abhi ke liye hata diya:
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}