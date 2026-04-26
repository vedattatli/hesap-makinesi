import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}
if (releaseTaskRequested && !hasReleaseSigning) {
    throw GradleException(
        "Signed Android release build requires android/key.properties. " +
            "Create it locally with storePassword, keyPassword, keyAlias, and storeFile."
    )
}
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    val requiredSigningKeys = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
    val missingSigningKeys = requiredSigningKeys.filter {
        keystoreProperties.getProperty(it).isNullOrBlank()
    }
    if (missingSigningKeys.isNotEmpty()) {
        throw GradleException(
            "android/key.properties is present but incomplete. Missing: ${missingSigningKeys.joinToString(", ")}. " +
                "Keep this file local and add storePassword, keyPassword, keyAlias, and storeFile."
        )
    }

    val configuredStoreFile = file(keystoreProperties.getProperty("storeFile"))
    if (!configuredStoreFile.exists()) {
        throw GradleException(
            "Android release keystore was not found at ${configuredStoreFile.absolutePath}. " +
                "Update storeFile in android/key.properties."
        )
    }
}

android {
    namespace = "com.vedattatli.hesapmakinesi"
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
        applicationId = "com.vedattatli.hesapmakinesi"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
