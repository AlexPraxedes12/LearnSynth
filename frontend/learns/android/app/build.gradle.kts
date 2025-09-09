import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Cargar propiedades de firma desde key.properties
val keystoreProperties = Properties().apply {
    val kpFile = file("key.properties")
    if (kpFile.exists()) {
        load(FileInputStream(kpFile))
    } else {
        logger.warn("⚠️ No se encontró key.properties en android/app/. El release no estará firmado.")
    }
}

android {
    namespace = "com.example.learns" // 🔁 cámbialo a tu namespace real
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.learns" // 🔁 cámbialo a tu appId real
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Flutter administra las dependencias principales
}
