package com.meshcore.meshcore_open

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.Rect
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.view.PixelCopy
import android.view.ScrollCaptureCallback
import android.view.ScrollCaptureSession
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.function.Consumer
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Lets Android's scrolling screenshot ("Capture more") extend past the
 * screen. Flutter draws into one surface, so the system cannot find or
 * scroll a list on its own: this callback asks Dart (ScrollCaptureService)
 * for the main scrollable's bounds, has it scroll for each requested strip,
 * and copies that strip from the Flutter surface into the capture session.
 */
@RequiresApi(Build.VERSION_CODES.S)
class FlutterScrollCapture(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : ScrollCaptureCallback {
    private val channel = MethodChannel(messenger, "meshcore_open/scroll_capture")
    private val handler = Handler(Looper.getMainLooper())
    private var host: View? = null

    /** Scroll bounds in Flutter-surface pixels. */
    private var flutterBounds = Rect()

    fun attach(view: View) {
        host = view
        view.scrollCaptureHint = View.SCROLL_CAPTURE_HINT_INCLUDE
        view.setScrollCaptureCallback(this)
    }

    fun detach() {
        host?.setScrollCaptureCallback(null)
        host = null
    }

    override fun onScrollCaptureSearch(signal: CancellationSignal, onReady: Consumer<Rect>) {
        val view = host
        if (view == null) {
            onReady.accept(Rect())
            return
        }
        invoke("search", null) { result ->
            val map = result as? Map<*, *>
            val surface = findFlutterSurface(view)
            if (map == null || surface == null) {
                onReady.accept(Rect())
                return@invoke
            }
            flutterBounds = Rect(
                map.int("left"),
                map.int("top"),
                map.int("right"),
                map.int("bottom"),
            )
            // Convert to the host view's coordinates.
            val hostLoc = IntArray(2).also { view.getLocationInWindow(it) }
            val surfLoc = IntArray(2).also { surface.getLocationInWindow(it) }
            val bounds = Rect(flutterBounds)
            bounds.offset(surfLoc[0] - hostLoc[0], surfLoc[1] - hostLoc[1])
            onReady.accept(bounds)
        }
    }

    override fun onScrollCaptureStart(
        session: ScrollCaptureSession,
        signal: CancellationSignal,
        onReady: Runnable,
    ) {
        invoke("start", null) { onReady.run() }
    }

    override fun onScrollCaptureImageRequest(
        session: ScrollCaptureSession,
        signal: CancellationSignal,
        captureArea: Rect,
        onComplete: Consumer<Rect>,
    ) {
        val args = mapOf("top" to captureArea.top, "bottom" to captureArea.bottom)
        invoke("scroll", args) { result ->
            val scrolled = ((result as? Number)?.toDouble() ?: 0.0).roundToInt()
            // The part of the requested strip now on screen, in scroll-bounds
            // coordinates relative to the current scroll position.
            val visibleTop = max(captureArea.top - scrolled, 0)
            val visibleBottom = min(captureArea.bottom - scrolled, flutterBounds.height())
            val left = max(captureArea.left, 0)
            val right = min(captureArea.right, flutterBounds.width())
            if (visibleBottom <= visibleTop || right <= left || signal.isCanceled) {
                onComplete.accept(Rect())
                return@invoke
            }
            val source = Rect(
                flutterBounds.left + left,
                flutterBounds.top + visibleTop,
                flutterBounds.left + right,
                flutterBounds.top + visibleBottom,
            )
            val captured = Rect(left, visibleTop + scrolled, right, visibleBottom + scrolled)
            // Give the raster thread a moment to present the scrolled frame.
            handler.postDelayed({
                copyPixels(source) { bitmap ->
                    if (bitmap == null || signal.isCanceled) {
                        onComplete.accept(Rect())
                        return@copyPixels
                    }
                    try {
                        val canvas = session.surface.lockHardwareCanvas()
                        try {
                            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
                            canvas.drawBitmap(bitmap, 0f, 0f, null)
                        } finally {
                            session.surface.unlockCanvasAndPost(canvas)
                        }
                        onComplete.accept(captured)
                    } catch (e: Exception) {
                        onComplete.accept(Rect())
                    } finally {
                        bitmap.recycle()
                    }
                }
            }, FRAME_SETTLE_MS)
        }
    }

    override fun onScrollCaptureEnd(onReady: Runnable) {
        invoke("end", null) { onReady.run() }
    }

    private fun copyPixels(source: Rect, done: (Bitmap?) -> Unit) {
        val view = host
        val surface = view?.let { findFlutterSurface(it) }
        val bitmap = Bitmap.createBitmap(source.width(), source.height(), Bitmap.Config.ARGB_8888)
        when (surface) {
            is SurfaceView -> PixelCopy.request(surface, source, bitmap, { code ->
                if (code == PixelCopy.SUCCESS) {
                    done(bitmap)
                } else {
                    bitmap.recycle()
                    done(null)
                }
            }, handler)
            is TextureView -> {
                val full = surface.bitmap
                if (full == null) {
                    bitmap.recycle()
                    done(null)
                } else {
                    android.graphics.Canvas(bitmap).drawBitmap(
                        full,
                        source,
                        Rect(0, 0, source.width(), source.height()),
                        null,
                    )
                    full.recycle()
                    done(bitmap)
                }
            }
            else -> {
                bitmap.recycle()
                done(null)
            }
        }
    }

    /** The view Flutter renders into (SurfaceView by default). */
    private fun findFlutterSurface(view: View): View? {
        if (view is SurfaceView || view is TextureView) return view
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                findFlutterSurface(view.getChildAt(i))?.let { return it }
            }
        }
        return null
    }

    private fun invoke(method: String, args: Any?, onResult: (Any?) -> Unit) {
        if (activity.isFinishing) {
            onResult(null)
            return
        }
        channel.invokeMethod(method, args, object : MethodChannel.Result {
            override fun success(result: Any?) = onResult(result)
            override fun error(code: String, message: String?, details: Any?) = onResult(null)
            override fun notImplemented() = onResult(null)
        })
    }

    private fun Map<*, *>.int(key: String): Int = (this[key] as? Number)?.toInt() ?: 0

    private companion object {
        const val FRAME_SETTLE_MS = 48L
    }
}
