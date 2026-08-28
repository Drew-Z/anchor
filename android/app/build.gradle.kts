plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingStoreFile = System.getenv("ANCHOR_SIGNING_STORE_FILE")
val signingStorePassword = System.getenv("ANCHOR_SIGNING_STORE_PASSWORD")
val signingKeyAlias = System.getenv("ANCHOR_SIGNING_KEY_ALIAS")
val signingKeyPassword = System.getenv("ANCHOR_SIGNING_KEY_PASSWORD")
val signingStoreType = System.getenv("ANCHOR_SIGNING_STORE_TYPE") ?: "PKCS12"
val hasReleaseSigning = listOf(
    signingStoreFile,
    signingStorePassword,
    signingKeyAlias,
    signingKeyPassword,
).all { !it.isNullOrBlank() } && file(signingStoreFile!!).isFile
val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (releaseBuildRequested && !hasReleaseSigning) {
    throw GradleException(
        "Release signing is not configured. Set " +
            "ANCHOR_SIGNING_STORE_FILE, ANCHOR_SIGNING_STORE_PASSWORD, " +
            "ANCHOR_SIGNING_KEY_ALIAS, and ANCHOR_SIGNING_KEY_PASSWORD. " +
            "Use `flutter build apk --debug` for private-alpha smoke tests.",
    )
}

android {
    namespace = "cc.eu.playlab.anchor"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "cc.eu.playlab.anchor"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("anchorRelease") {
                storeFile = file(signingStoreFile!!)
                storeType = signingStoreType
                storePassword = signingStorePassword
                keyAlias = signingKeyAlias
                keyPassword = signingKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("anchorRelease")
            }
            // 禁用 R8 代码混淆，避免 release 模式下第三方库被混淆导致渲染异常
            isMinifyEnabled = false
            isShrinkResources = false
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

dependencies {
    implementation("androidx.documentfile:documentfile:1.1.0")
}
