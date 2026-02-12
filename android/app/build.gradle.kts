plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.barolit.icourier"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // In android/app/build.gradle.kts

    signingConfigs {
        // 1. Custom 'legacy' config
        create("legacy") {
            storeFile = file("/Users/temis/Projects/Flutter/iCourierApps_PlaySignKey/android.keystore")
            storePassword = "Msaxapta0201"
            keyAlias = "android"
            keyPassword = "Msaxapta0201"
        }

        // 2. Custom 'recent' config
        create("recent") {
            storeFile = file("/Users/temis/Projects/Flutter/iCourierApps_PlaySignKey/AndroidKey.keystore")
            storePassword = "Msaxapta0201"
            keyAlias = "androidkey"
            keyPassword = "Msaxapta0201"
        }

        // 3. Define the 'release' config using create()
        create("release") {
            storeFile = file("/Users/temis/Projects/Flutter/iCourierApps_PlaySignKey/upload-keystore.jks")
            storePassword = "Msaxapta0201"
            keyAlias = "upload"
            keyPassword = "Msaxapta0201"
        }

        // 4. Custom 'codemagic' config
        create("codemagic") {
            val isCI = System.getenv()["CI"].toBoolean()

            if (isCI) {
                storeFile = file(System.getenv()["CM_KEYSTORE_PATH"])
                storePassword = System.getenv()["CM_KEYSTORE_PASSWORD"]
                keyAlias = System.getenv()["CM_KEY_ALIAS"]
                keyPassword = System.getenv()["CM_KEY_PASSWORD"]
            } else {
                storeFile = file("/Users/temis/Projects/Flutter/iCourierApps_PlaySignKey/android.keystore")
                storePassword = "Msaxapta0201"
                keyAlias = "android"
                keyPassword = "Msaxapta0201"
            }
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
            versionCode = 5202601
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
            versionCode = 5202601
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
        create("atiempo") {
            dimension = "app"
            applicationId = "com.barolit.atiempo"
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

    buildTypes {
        // getByName("release") is used to modify the standard 'release' build type
        getByName("release") {
//            signingConfig = signingConfigs.getByName("release")
//             signingConfig = signingConfigs.getByName("recent")
             signingConfig = signingConfigs.getByName("legacy")
        }
    }
}

dependencies {
    // ACTION 2: Add the Desugar Library
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // You might also see:
    // implementation(project(":flutter"))
    // implementation(kotlin("stdlib-jdk8"))
}

flutter {
    source = "../.."
}
