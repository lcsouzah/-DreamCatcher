@file:Suppress("DEPRECATION")

import com.android.build.gradle.BaseExtension
import org.gradle.api.file.Directory
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    // Apply Kotlin plugin if Kotlin sources are present but plugin is not applied
    pluginManager.withPlugin("com.android.library") {
        if (file("src/main/kotlin").exists() && !plugins.hasPlugin("org.jetbrains.kotlin.android")) {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }
    }
    pluginManager.withPlugin("com.android.application") {
        if (file("src/main/kotlin").exists() && !plugins.hasPlugin("org.jetbrains.kotlin.android")) {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }
    }

    afterEvaluate {
        val android = extensions.findByType(BaseExtension::class.java)
        android?.apply {
            if (namespace == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifestContent = manifestFile.readText()
                    val manifestPackage = Regex("package=\"([^\"]+)\"")
                        .find(manifestContent)
                        ?.groupValues
                        ?.getOrNull(1)
                    if (manifestPackage != null) {
                        namespace = manifestPackage
                    }
                }
            }
            compileSdkVersion(36)
            defaultConfig.targetSdkVersion(36)
            compileOptions.sourceCompatibility = JavaVersion.VERSION_17
            compileOptions.targetCompatibility = JavaVersion.VERSION_17
        }

        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(JvmTarget.JVM_17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}