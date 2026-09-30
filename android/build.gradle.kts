import org.gradle.api.tasks.compile.JavaCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Pin each module's Kotlin compile target to its own javac target.
// Several Flutter plugin modules never set a Kotlin `jvmTarget` (e.g.
// shizuku_api, whose `kotlinOptions` guard no longer applies on Kotlin 2.3),
// so Kotlin falls back to the Gradle JVM's default (which differs per
// machine — observed as high as 25) while javac uses the module's own
// source/target, failing with:
//   "Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks"
// Only Kotlin tasks are adjusted; Java tasks are left untouched because
// AGP's android.jar bootclasspath wiring must not be disturbed.
// Runs in projectsEvaluated so every module (and AGP) has finished
// configuring its tasks first.
gradle.projectsEvaluated {
    subprojects {
        val javaTarget = tasks.withType<JavaCompile>()
            .mapNotNull { it.targetCompatibility ?: it.sourceCompatibility }
            .firstOrNull() ?: "17"
        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(JvmTarget.fromTarget(javaTarget))
        }
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
