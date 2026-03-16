import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.nio.file.Files
import java.nio.file.StandardCopyOption

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val enableSplitPerAbi = providers.gradleProperty("split-per-abi").orNull == "true"

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

    buildTypes {
        debug {
            // versionName already includes build time for easier installs.
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
