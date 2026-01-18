plugins {
    id("java")
    id("org.jetbrains.intellij") version "1.17.3"
}

group = "com.melu.dataforge"
version = "1.0.0"

repositories {
    mavenCentral()
}

intellij {
    version.set("2025.2.3")
    type.set("IC") // Use "IU" for Ultimate, "IC" for Community
}

tasks {
    patchPluginXml {
        sinceBuild.set("251")
        untilBuild.set("252.*")
    }
    
    runIde {
        maxHeapSize = "2g"
    }
    
    // Skip buildSearchableOptions task to avoid build failures
    buildSearchableOptions {
        enabled = false
    }
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}