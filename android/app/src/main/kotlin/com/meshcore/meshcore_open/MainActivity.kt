package com.meshcore.meshcore_open

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import androidx.activity.enableEdgeToEdge
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.service.ForegroundServiceManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.util.ViewUtils

// FlutterFragmentActivity (a ComponentActivity) so enableEdgeToEdge() works:
// Android 15+ enforces edge-to-edge for apps targeting SDK 35, and the app
// already draws behind the system bars and handles insets in Flutter.
//
// The Flutter engine, which holds the link with the radio, is cached per
// process so it outlives the activity while the background service runs (app
// swiped away). If the service stops while no activity exists, the next launch
// replaces the engine with a new one, so it starts fresh. Until then the old
// engine keeps answering notification actions.
class MainActivity : FlutterFragmentActivity() {
    private companion object {
        const val ENGINE_ID = "meshcore_main"

        // Time the app gets after the service stops to finish its disconnect
        // and the writes it still has queued (the longest waits 5 s).
        const val REPLACE_DELAY_MS = 8_000L

        // MainActivity instances between onCreate and onDestroy.
        var liveActivities = 0

        // Uptime at which the engine may be replaced, set when the service
        // ends while no activity exists; 0 when nothing is pending. Uptime,
        // like Dart timers, does not advance in deep sleep.
        var replaceEngineAt = 0L

        private val serviceListener = object : FlutterForegroundTaskLifecycleListener {
            override fun onEngineCreate(flutterEngine: FlutterEngine?) {}
            override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}
            override fun onTaskRepeatEvent() {}
            override fun onEngineWillDestroy() {}

            // The service task ended (service stopped or restarted).
            override fun onTaskDestroy() {
                if (liveActivities > 0) return
                replaceEngineAt = SystemClock.uptimeMillis() + REPLACE_DELAY_MS
            }
        }

        fun destroyEngine() {
            val cache = FlutterEngineCache.getInstance()
            val engine = cache.get(ENGINE_ID) ?: return
            cache.remove(ENGINE_ID)
            engine.destroy()
        }
    }

    private var scrollCapture: FlutterScrollCapture? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        // A recreated activity keeps its old intent: mark it so a notification
        // tap in it is not routed a second time.
        if (savedInstanceState != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY)
        }
        // The service ended while no activity existed: start with a new engine
        // if the app itself stopped the service (it decided the link is over),
        // had time to finish its writes, and nothing restarted the service.
        // Otherwise keep the engine and its state.
        val replaceAt = replaceEngineAt
        replaceEngineAt = 0L
        if (replaceAt != 0L && SystemClock.uptimeMillis() >= replaceAt &&
            !ForegroundServiceManager().isRunningService() &&
            ForegroundServiceStatus.getData(applicationContext).isCorrectlyStopped()
        ) {
            destroyEngine()
        }
        liveActivities++
        // Before super.onCreate(): a restored fragment looks the engine up there.
        ensureEngine()
        super.onCreate(savedInstanceState)
    }

    // Creates and starts the engine the same way FlutterFragmentActivity does
    // for its own engine, but with the application context so it can outlive
    // this activity. Plugins are registered by the FlutterEngine constructor,
    // and the USB plugin here, so a USB link also lives with the engine.
    private fun ensureEngine() {
        val cache = FlutterEngineCache.getInstance()
        if (cache.contains(ENGINE_ID)) return
        @Suppress("DEPRECATION")
        val shellArgs = FlutterShellArgs.fromIntent(intent).toArray()
        val engine = FlutterEngine(applicationContext, shellArgs)
        engine.plugins.add(MeshcoreUsbFunctions())
        ViewUtils.calculateMaximumDisplayMetrics(this, engine)
        engine.navigationChannel.setInitialRoute(initialRoute ?: "/")
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
            dartEntrypointArgs,
        )
        cache.put(ENGINE_ID, engine)
        // Only processes with a UI engine listen; the list keeps one copy.
        FlutterForegroundTaskPlugin.addTaskLifecycleListener(serviceListener)
    }

    override fun getCachedEngineId(): String = ENGINE_ID

    // Only onDestroy below may destroy the engine, not an intent extra.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
        super.onDestroy()
        liveActivities--
        // Closed without the background service: destroy the engine as
        // before, so the next launch is a cold start.
        if (liveActivities == 0 && isFinishing && !ForegroundServiceManager().isRunningService()) {
            destroyEngine()
        }
    }
}
