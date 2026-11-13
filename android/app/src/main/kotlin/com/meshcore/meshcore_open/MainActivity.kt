package com.meshcore.meshcore_open

import android.os.Build
import android.os.Bundle
import android.view.View
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// FlutterFragmentActivity (a ComponentActivity) so enableEdgeToEdge() works:
// Android 15+ enforces edge-to-edge for apps targeting SDK 35, and the app
// already draws behind the system bars and handles insets in Flutter.
class MainActivity : FlutterFragmentActivity() {
    private val usbFunctions by lazy { MeshcoreUsbFunctions(this) }
    private var scrollCapture: FlutterScrollCapture? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usbFunctions.configureFlutterEngine(flutterEngine)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            scrollCapture?.detach()
            scrollCapture = FlutterScrollCapture(
                this,
                flutterEngine.dartExecutor.binaryMessenger,
            ).also { it.attach(findViewById<View>(android.R.id.content)) }
        }
    }

    override fun onDestroy() {
        scrollCapture?.detach()
        scrollCapture = null
        usbFunctions.dispose()
        super.onDestroy()
    }
}
