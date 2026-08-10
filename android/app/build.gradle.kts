plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.barolit.icourier"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // In android/app/build.gradle.kts

    signingConfigs {
        create("release") {
            System.getenv("ANDROID_KEYSTORE_PATH")?.let {
                storeFile = file(it)
            }
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.barolit.icourier"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["urlScheme"] = "icourier"
    }

    buildFeatures {
        compose = true
    }

    // This line should be placed just inside the 'android' block,
// outside the productFlavors block:
    flavorDimensions.add("app")

// The productFlavors block:
    productFlavors {
        create("domex") {
            dimension = "app"
            applicationId = "com.barolit.domex"
            versionCode = 5202601
        }
        create("bmcargo") {
            dimension = "app"
            applicationId = "com.barolit.bmcargo"
            versionCode = 5202605
        }
        create("jetpack") {
            dimension = "app"
            applicationId = "com.barolit.jetpack"
            versionCode = 5202601
        }
        create("almapaq") {
            dimension = "app"
            applicationId = "com.barolit.almapaq"
            versionCode = 5202601
        }
        create("beexpress") {
            dimension = "app"
            applicationId = "com.barolit.beexpress"
            versionCode = 5202601
        }
        create("boxpaq") {
            dimension = "app"
            applicationId = "com.barolit.boxpaq"
            versionCode = 5202601
        }
        create("encargopaq") {
            dimension = "app"
            applicationId = "com.barolit.encargopaq"
            versionCode = 5202603
        }
        create("pintopaq") {
            dimension = "app"
            applicationId = "com.barolit.pintopaq"
            versionCode = 5202601
        }
        create("caribepack") {
            dimension = "app"
            applicationId = "com.barolit.caribepackapp"
        }
        create("tls") {
            dimension = "app"
            applicationId = "com.barolit.tls"
            versionCode = 5202604
        }
        create("cps") {
            dimension = "app"
            applicationId = "com.barolit.cps"
        }
        create("cainca") {
            dimension = "app"
            applicationId = "com.barolit.cainca"
        }
        create("gopack") {
            dimension = "app"
            applicationId = "com.barolit.gopack"
        }
        create("telo") {
            dimension = "app"
            applicationId = "com.barolit.telo"
        }
        create("priority") {
            dimension = "app"
            applicationId = "com.barolit.priority"
        }
        create("qm") {
            dimension = "app"
            applicationId = "com.barolit.qm"
        }
        create("tdexpress") {
            dimension = "app"
            applicationId = "com.barolit.tdexpress"
        }
        create("clickpack") {
            dimension = "app"
            applicationId = "com.barolit.clickpack"
        }
        create("skyhigh") {
            dimension = "app"
            applicationId = "com.barolit.skyhigh"
        }
        create("blumbox") {
            dimension = "app"
            applicationId = "com.barolit.blumbox"
        }
        create("cargospot") {
            dimension = "app"
            applicationId = "com.barolit.cargospot"
        }
        create("arribex") {
            dimension = "app"
            applicationId = "com.barolit.arribex"
        }
        create("acc") {
            dimension = "app"
            applicationId = "com.barolit.acc"
        }
        create("atiempo") {
            dimension = "app"
            applicationId = "com.barolit.atiempo"
        }
        create("brodpaq") {
            dimension = "app"
            applicationId = "com.barolit.brodpaq"
        }
        create("cargowise") {
            dimension = "app"
            applicationId = "com.barolit.cargowise"
        }
        create("flypack") {
            dimension = "app"
            applicationId = "com.barolit.flypack"
        }
        create("mcccargo") {
            dimension = "app"
            applicationId = "com.barolit.mcccargo"
        }
        create("ecopaq") {
            dimension = "app"
            applicationId = "com.barolit.ecopaq"
        }
        create("inbox") {
            dimension = "app"
            applicationId = "com.barolit.inbox"
        }
        create("tupaq") {
            dimension = "app"
            applicationId = "com.barolit.tupaq"
        }
        create("swoop") {
            dimension = "app"
            applicationId = "com.barolit.swoop"
        }
        create("taino") {
            dimension = "app"
            applicationId = "com.barolit.taino"
            versionCode = 5202601
        }
        create("fixocargo") {
            dimension = "app"
            applicationId = "com.barolit.fixocargo"
            versionCode = 5202601
        }
        create("picknsend") {
            dimension = "app"
            applicationId = "com.barolit.picknsend"
            versionCode = 5202601
        }
    }

    productFlavors.configureEach {
        manifestPlaceholders["urlScheme"] = name
    }

    buildTypes {
        // getByName("release") is used to modify the standard 'release' build type
        getByName("release") {
            if (System.getenv("ANDROID_KEYSTORE_PATH") != null) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

dependencies {
    // ACTION 2: Add the Desugar Library
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.glance:glance-appwidget:1.1.1")
    testImplementation("junit:junit:4.13.2")

    // You might also see:
    // implementation(project(":flutter"))
    // implementation(kotlin("stdlib-jdk8"))
}

flutter {
    source = "../.."
}
