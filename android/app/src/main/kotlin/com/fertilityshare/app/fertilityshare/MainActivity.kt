package com.fertilityshare.app.fertilityshare

import android.os.Bundle // Required for onCreate
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen // Import for installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Handle the splash screen transition.
        val splashScreen = installSplashScreen() // Call this before super.onCreate()

        super.onCreate(savedInstanceState)
        // Plugins are usually registered automatically in newer Flutter projects.
    }
}
