package com.fertilityshare.app.fertilityshare

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import android.os.Handler
import android.os.Looper

class MainActivity: FlutterActivity() {
    private var keepOnScreen = true

    override fun onCreate(savedInstanceState: Bundle?) {
        // 1. Install the splash screen BEFORE super.onCreate()
        val splashScreen = installSplashScreen()
        
        super.onCreate(savedInstanceState)
        
        // 2. Control visibility with a condition
        splashScreen.setKeepOnScreenCondition { keepOnScreen }
        
        // 3. Force removal as soon as the condition is met to prevent focus issues
        splashScreen.setOnExitAnimationListener { splashScreenView ->
            splashScreenView.remove()
        }
        
        // 4. Maximum cap timer: Dismiss after 2 seconds if Flutter isn't ready yet
        Handler(Looper.getMainLooper()).postDelayed({
            keepOnScreen = false
        }, 2000)
    }

    // 5. "As soon as it's ready": Dismiss when Flutter renders its first frame
    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        keepOnScreen = false
    }
}
