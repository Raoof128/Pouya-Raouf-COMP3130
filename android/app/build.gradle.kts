import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val hasGoogleServicesJson = file("google-services.json").exists()

// Load secrets from secrets.properties if it exists
val secretsFile = rootProject.file("secrets.properties")
val secrets = Properties()
if (secretsFile.exists()) {
    secretsFile.inputStream().use { secrets.load(it) }
}

// Also load local.properties for IDE / direct flutter run fallback
val localPropertiesFile = rootProject.file("local.properties")
val localProps = Properties()
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProps.load(it) }
}

val googleMapsApiKey: String =
    (secrets.getProperty("GOOGLE_MAPS_API_KEY"))
        ?: (localProps.getProperty("GOOGLE_MAPS_API_KEY"))
        ?: (project.findProperty("GOOGLE_MAPS_API_KEY") as String?).takeIf { !it.isNullOrEmpty() }
        ?: System.getenv("GOOGLE_MAPS_API_KEY").orEmpty().ifEmpty { null }
        ?: ""

if (hasGoogleServicesJson) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "io.mqnavigation.mq_navigation"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.mqnavigation.mq_navigation"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
    }

    signingConfigs {
        create("release") {
            val keystoreFile = project.findProperty("RELEASE_KEYSTORE_FILE") as String?
            if (keystoreFile != null && file(keystoreFile).exists()) {
                storeFile = file(keystoreFile)
                storePassword = project.findProperty("RELEASE_KEYSTORE_PASSWORD") as String? ?: ""
                keyAlias = project.findProperty("RELEASE_KEY_ALIAS") as String? ?: ""
                keyPassword = project.findProperty("RELEASE_KEY_PASSWORD") as String? ?: ""
            }
        }
    }

    buildTypes {
        release {
            val hasReleaseKeystore = signingConfigs.getByName("release").storeFile != null
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Fallback to debug keys for local development only.
                signingConfigs.getByName("debug")
            }
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
