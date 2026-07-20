import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun getSigningProperties(): Properties? {
    val env = System.getenv()
    if (env.containsKey("ANDROID_STORE_FILE")) {
        return Properties().apply {
            setProperty("storeFile", env["ANDROID_STORE_FILE"])
            setProperty("storePassword", env["ANDROID_STORE_PASSWORD"] ?: "changeit")
            setProperty("keyPassword", env["ANDROID_KEY_PASSWORD"] ?: "changeit")
            setProperty("keyAlias", env["ANDROID_KEY_ALIAS"] ?: "taweqa")
        }
    }
    val propsFile = rootProject.file("key.properties")
    if (propsFile.exists()) {
        return Properties().apply {
            load(propsFile.inputStream())
        }
    }
    return null
}

android {
    namespace = "com.example.taweqa_ogretk"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.mahmoud11199.taweqa_ogretk"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val props = getSigningProperties()
            if (props != null) {
                storeFile = rootProject.file(props["storeFile"] ?: "app/keystore.jks")
                storePassword = props["storePassword"] as? String ?: "changeit"
                keyAlias = props["keyAlias"] as? String ?: "taweqa"
                keyPassword = props["keyPassword"] as? String ?: "changeit"
            }
        }
    }

    buildTypes {
        release {
            val relSigning = signingConfigs.findByName("release")
            signingConfig = relSigning ?: signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
