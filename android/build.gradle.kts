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
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        val androidExtension = extensions.findByName("android")
        if (androidExtension != null) {
            val groupPath = project.group.toString()
            if (groupPath.isNotEmpty()) {
                (androidExtension as com.android.build.gradle.BaseExtension).apply {
                    if (namespace == null) {
                        namespace = groupPath
                    }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
