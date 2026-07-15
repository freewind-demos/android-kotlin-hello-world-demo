plugins {
    id("com.android.application")
}

android {
    namespace = "demos.android.kotlin.hello.world.demo"
    compileSdk = 36

    defaultConfig {
        applicationId = "demos.android.kotlin.hello.world.demo"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.appcompat:appcompat:1.7.1")
}
