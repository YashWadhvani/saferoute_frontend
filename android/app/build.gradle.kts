import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.saferoute_frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // kotlinOptions deprecated in this location; configure JVM target below using tasks

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.saferoute_frontend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Load MAPS_API_KEY from environment or from a .env file at project root.
        // Priority: System env MAPS_API_KEY > .env file (MAPS_API_KEY=...) > empty string
        // Robustly search upward from the module directory for a .env file
        fun findEnvFile(start: File?): File? {
            var dir = start
            while (dir != null) {
                val candidate = File(dir, ".env")
                if (candidate.exists()) return candidate
                dir = dir.parentFile
            }
            return null
        }

        val mapsApiKeyFromEnv = System.getenv("MAPS_API_KEY")
        val envFile = findEnvFile(projectDir)
        val mapsApiKeyFromDotEnv: String? = envFile?.let { file ->
            file.readLines()
                .firstOrNull { it.trim().startsWith("MAPS_API_KEY=") }
                ?.split("=", limit = 2)?.getOrNull(1)
                ?.trim()?.trim('"')
        }

        val mapsApiKey = mapsApiKeyFromEnv ?: mapsApiKeyFromDotEnv ?: ""

        // Log for debugging during configuration
        println("[build.gradle.kts] MAPS_API_KEY length=${mapsApiKey.length}")

        if (mapsApiKey.isBlank()) {
            throw GradleException(
                "MAPS_API_KEY is empty. Set environment variable MAPS_API_KEY or add MAPS_API_KEY=... to a .env file in the project root."
            )
        }

        // Expose to AndroidManifest as manifest placeholder
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Ensure Kotlin compiler uses JVM target 17 using the new compilerOptions DSL
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        // Use the typed JvmTarget enum to set JVM target to 17
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
