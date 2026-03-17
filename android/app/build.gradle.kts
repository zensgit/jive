import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.Properties
import java.nio.file.Files
import java.nio.file.StandardCopyOption

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val enableSplitPerAbi = providers.gradleProperty("split-per-abi").orNull == "true"
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun propOrEnv(key: String, envKey: String): String? {
    return (keystoreProperties.getProperty(key) ?: System.getenv(envKey))
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
}

val releaseStoreFilePath = propOrEnv("storeFile", "JIVE_ANDROID_STORE_FILE")
val releaseStorePassword = propOrEnv("storePassword", "JIVE_ANDROID_STORE_PASSWORD")
val releaseKeyAlias = propOrEnv("keyAlias", "JIVE_ANDROID_KEY_ALIAS")
val releaseKeyPassword = propOrEnv("keyPassword", "JIVE_ANDROID_KEY_PASSWORD")
val hasReleaseSigning =
    releaseStoreFilePath != null &&
        releaseStorePassword != null &&
        releaseKeyAlias != null &&
        releaseKeyPassword != null &&
        file(releaseStoreFilePath).exists()

android {
    namespace = "com.jive.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    val buildTimeName = SimpleDateFormat("yyyyMMdd-HHmm", Locale.US).format(Date())
    val buildTimeCode = 2_100_000_000 + ((System.currentTimeMillis() / 60000L).toInt() % 10_000_000)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jivemoney.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = buildTimeCode
        versionName = "${flutter.versionName}-$buildTimeName"
    }

    flavorDimensions += "env"
    productFlavors {
        create("prod") {
            dimension = "env"
            applicationId = "com.jivemoney.app"
            manifestPlaceholders["appLabel"] = "Jive"
            manifestPlaceholders["appLabelAccessibility"] = "Jive"
        }
        create("auto") {
            dimension = "env"
            applicationId = "com.jivemoney.app.auto"
            manifestPlaceholders["appLabel"] = "Jive Auto"
            manifestPlaceholders["appLabelAccessibility"] = "Jive Auto (无障碍版)"
        }
        create("dev") {
            dimension = "env"
            applicationId = "com.jivemoney.app.dev"
            manifestPlaceholders["appLabel"] = "Jive Dev"
            manifestPlaceholders["appLabelAccessibility"] = "Jive Dev (无障碍版)"
        }
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            // versionName already includes build time for easier installs.
        }
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    if (enableSplitPerAbi) {
        packaging {
            jniLibs {
                keepDebugSymbols += "**/*.so"
            }
        }
    }
}

if (enableSplitPerAbi) {
    android.applicationVariants.all {
        val variantNameCapitalized = name.replaceFirstChar { char ->
            if (char.isLowerCase()) char.titlecase(Locale.US) else char.toString()
        }
        val buildTypeSegment = buildType.name.lowercase(Locale.US)
        val flavorSegment = flavorName
            ?.takeIf { it.isNotBlank() }
            ?.lowercase(Locale.US)
            ?.let { "$it-" }
            ?: ""
        val compatTaskName = "linkFlutterApk${variantNameCapitalized}"

        val compatTask = tasks.register(compatTaskName) {
            doLast {
                val flutterApkDir = rootProject.layout.projectDirectory
                    .dir("../build/app/outputs/flutter-apk")
                    .asFile
                val expectedName = "app-${flavorSegment}${buildTypeSegment}.apk"
                val expectedFile = flutterApkDir.resolve(expectedName)
                val candidateSuffix = "-${flavorSegment}${buildTypeSegment}.apk"
                val candidateFiles = flutterApkDir.listFiles()
                    ?.filter { file ->
                        file.isFile &&
                            file.name.startsWith("app-") &&
                            file.name.endsWith(candidateSuffix) &&
                            file.name != expectedName
                    }
                    ?.sortedBy { file -> file.name }
                    .orEmpty()

                if (candidateFiles.size != 1) {
                    logger.lifecycle(
                        "Skipping legacy flutter-apk link for ${name}: found ${candidateFiles.size} candidates for $expectedName",
                    )
                    return@doLast
                }

                val sourceFile = candidateFiles.single().toPath()
                val targetFile = expectedFile.toPath()
                Files.deleteIfExists(targetFile)
                try {
                    Files.createSymbolicLink(targetFile, sourceFile.fileName)
                } catch (_: UnsupportedOperationException) {
                    Files.copy(sourceFile, targetFile, StandardCopyOption.REPLACE_EXISTING)
                } catch (_: java.nio.file.FileSystemException) {
                    Files.copy(sourceFile, targetFile, StandardCopyOption.REPLACE_EXISTING)
                }
            }
        }

        tasks.named("assemble${variantNameCapitalized}").configure {
            finalizedBy(compatTask)
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // google_mlkit_text_recognition requires app-level language packages in release builds.
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
}
