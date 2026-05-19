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

    // Using afterEvaluate to override compileSdkVersion for subprojects (plugins)
    // that are still targeting Android 34, upgrading them to 35.
    afterEvaluate {
        project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            if (compileSdkVersion == "android-34" || compileSdkVersion == "34") {
                compileSdkVersion(35)
            }
        }
    }

    // Specific fix for flutter_bluetooth_serial namespace issue
    if (project.name == "flutter_bluetooth_serial") {
        project.plugins.withId("com.android.library") {
            val android = project.extensions.findByName("android")
            android?.let {
                try {
                    it.javaClass.getMethod("setNamespace", String::class.java).invoke(it, "io.github.edufolly.flutterbluetoothserial")
                } catch (e: Exception) {
                    // Fallback or ignore if method not found
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
