import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
}

android {
    namespace = "io.github.luanthierry.offlinegym"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.luanthierry.offlinegym"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")
            val envStoreFile = System.getenv("ANDROID_KEYSTORE_PATH")
            val propStoreFile = keystoreProperties.getProperty("storeFile")
            val effectiveStoreFile = if (!envStoreFile.isNullOrBlank()) envStoreFile else propStoreFile
            storeFile = effectiveStoreFile?.let { file(it) }
            storePassword = System.getenv("ANDROID_STORE_PASSWORD") ?: keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Validar somente quando uma tarefa release faz parte da execução.
// Configurar o projeto (inclusive debug) não deve exigir credenciais privadas.
gradle.taskGraph.whenReady {
    if (allTasks.any { it.project == project && it.name.contains("Release") }) {
        val required = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
        if (!keystorePropertiesFile.exists() ||
            required.any { keystoreProperties.getProperty(it).isNullOrBlank() } ||
            android.signingConfigs.getByName("release").storeFile?.isFile != true) {
            throw GradleException("Configure uma assinatura release válida em android/key.properties.")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
