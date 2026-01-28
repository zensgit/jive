allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// FIX: Auto-add namespace to libraries (Isar fix)
subprojects {
    project.evaluationDependsOn(":app")
    
    // Apply namespace to libraries that are missing it
    project.plugins.withId("com.android.library") {
        val android = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        val desiredCompileSdk = 36
        val compileSdk = android.compileSdk ?: 0
        if (compileSdk < desiredCompileSdk) {
            // Keep library modules in sync with the app compileSdk.
            android.compileSdk = desiredCompileSdk
        }
        if (android.namespace == null) {
            android.namespace = project.group.toString()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
