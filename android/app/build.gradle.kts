import java.util.*
import java.io.*

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { fis ->
        keystoreProperties.load(fis)
    }
}

android {
    namespace = "com.novacode.xumaa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

   signingConfigs {
    create("release") {
        val alias = keystoreProperties["keyAlias"]?.toString()
        val keyPass = keystoreProperties["keyPassword"]?.toString()
        val storePass = keystoreProperties["storePassword"]?.toString()
        val storeFilePath = keystoreProperties["storeFile"]?.toString()



        if (alias != null && keyPass != null && storePass != null && storeFilePath != null) {
            keyAlias = alias
            keyPassword = keyPass
            storeFile = file(storeFilePath)
            storePassword = storePass
        } else {
            throw GradleException("❌ Falta una propiedad en el archivo key.properties")
        }
    }
}


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.novacode.xumaa"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isShrinkResources = true
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
