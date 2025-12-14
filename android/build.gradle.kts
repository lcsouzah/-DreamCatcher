import com.android.build.gradle.BaseExtension
import org.gradle.api.Project
import org.gradle.api.file.Directory
import org.gradle.kotlin.dsl.findByType

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
    project.evaluationDependsOn(":app")
}

fun Project.applyNamespaceFallback() {
    val androidExtension = extensions.findByType(BaseExtension::class.java) ?: return
    if (androidExtension.namespace?.isNotBlank() == true) return

    val manifestFile = file("src/main/AndroidManifest.xml")
    if (!manifestFile.exists()) return

    val manifestContent = manifestFile.readText()
    val manifestPackage = Regex("package=\"([^\"]+)\"")
        .find(manifestContent)
        ?.groupValues
        ?.getOrNull(1)

    if (!manifestPackage.isNullOrBlank()) {
        androidExtension.namespace = manifestPackage
    }
}

subprojects {
    pluginManager.withPlugin("com.android.library") {
        applyNamespaceFallback()
    }

    pluginManager.withPlugin("com.android.application") {
        applyNamespaceFallback()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}