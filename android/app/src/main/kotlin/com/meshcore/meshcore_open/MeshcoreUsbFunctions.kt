package com.meshcore.meshcore_open

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MeshcoreUsbFunctions(
    private val activity: Activity,
) {
    private companion object {
        const val usbRecipientInterface = 0x01
    }

    private val usbMethodChannelName = "meshcore_open/android_usb_serial"
    private val usbEventChannelName = "meshcore_open/android_usb_serial_events"
    private val usbPermissionAction = "com.meshcore.meshcore_open.USB_PERMISSION"

    private val usbManager by lazy {
        activity.getSystemService(Context.USB_SERVICE) as UsbManager
    }
    private val mainHandler = Handler(Looper.getMainLooper())
    private val usbIoExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    @Volatile private var eventSink: EventChannel.EventSink? = null
    @Volatile private var usbConnection: UsbDeviceConnection? = null
    @Volatile private var usbInEndpoint: UsbEndpoint? = null
    @Volatile private var usbOutEndpoint: UsbEndpoint? = null
    @Volatile private var controlInterface: UsbInterface? = null
    @Volatile private var dataInterface: UsbInterface? = null
    private var readThread: Thread? = null
    @Volatile private var isReading = false
    @Volatile private var connectedDeviceName: String? = null

    private var pendingConnectResult: MethodChannel.Result? = null
    private var pendingConnectPortName: String? = null
    private var pendingConnectBaudRate: Int = 115200

    private data class PortConfig(
        val controlInterface: UsbInterface?,
        val dataInterface: UsbInterface,
        val inEndpoint: UsbEndpoint,
        val outEndpoint: UsbEndpoint,
    )

    private val permissionReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                        handleUsbDetached(intent)
                        return
                    }
                    usbPermissionAction -> Unit
                    else -> return
                }

                val result = pendingConnectResult
                val portName = pendingConnectPortName
                pendingConnectResult = null
                pendingConnectPortName = null

                if (result == null || portName == null) {
                    return
                }

                val device = findUsbDevice(portName)
                if (device == null) {
                    result.error(
                        "usb_device_missing",
                        null,
                        null,
                    )
                    return
                }

                val granted =
                    intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                if (!granted || !usbManager.hasPermission(device)) {
                    result.error("usb_permission_denied", null, null)
                    return
                }

                openUsbDevice(device, pendingConnectBaudRate, result)
            }
        }

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        registerUsbPermissionReceiver()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, usbMethodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listPorts" -> result.success(listUsbPorts())
                    "connect" -> handleUsbConnect(call, result)
                    "write" -> handleUsbWrite(call, result)
                    "disconnect" -> {
                        scheduleCloseUsbConnection {
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, usbEventChannelName)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                        eventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        eventSink = null
                    }
                },
            )
    }

    fun dispose() {
        closeUsbConnection()
        usbIoExecutor.shutdownNow()
        try {
            activity.unregisterReceiver(permissionReceiver)
        } catch (_: IllegalArgumentException) {
        }
    }

    private fun registerUsbPermissionReceiver() {
        val filter =
            IntentFilter().apply {
                addAction(usbPermissionAction)
                addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
            }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.registerReceiver(permissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            activity.registerReceiver(permissionReceiver, filter)
        }
    }

    private fun listUsbPorts(): List<String> {
        return usbManager.deviceList.values.map { device ->
            val productName = device.productName ?: "USB Serial Device"
            val vendorProduct =
                String.format(
                    Locale.US,
                    "VID:%04X PID:%04X",
                    device.vendorId,
                    device.productId,
                )
            "${device.deviceName} - $productName - $vendorProduct"
        }
    }

    private fun handleUsbConnect(call: MethodCall, result: MethodChannel.Result) {
        val portName = call.argument<String>("portName")
        val baudRate = call.argument<Int>("baudRate") ?: 115200
        if (portName.isNullOrBlank()) {
            result.error("usb_invalid_port", null, null)
            return
        }

        val device = findUsbDevice(portName)
        if (device == null) {
            result.error("usb_device_missing", null, null)
            return
        }

        if (usbManager.hasPermission(device)) {
            openUsbDevice(device, baudRate, result)
            return
        }

        if (pendingConnectResult != null) {
            result.error("usb_busy", null, null)
            return
        }

        pendingConnectResult = result
        pendingConnectPortName = portName
        pendingConnectBaudRate = baudRate

        val permissionIntent = PendingIntent.getBroadcast(
            activity,
            0,
            Intent(usbPermissionAction).setPackage(activity.packageName),
            pendingIntentFlags(),
        )
        usbManager.requestPermission(device, permissionIntent)
    }

    private fun handleUsbWrite(call: MethodCall, result: MethodChannel.Result) {
        val data = call.argument<ByteArray>("data")
        val connection = usbConnection
        val endpoint = usbOutEndpoint
        if (data == null) {
            result.error("usb_invalid_data", null, null)
            return
        }
        if (connection == null || endpoint == null) {
            result.error("usb_not_connected", null, null)
            return
        }

        usbIoExecutor.execute {
            try {
                writeToDevice(data)
                mainHandler.post { result.success(null) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("usb_write_failed", error.message, null)
                }
            }
        }
    }

    private fun findUsbDevice(portName: String): UsbDevice? {
        val devices = usbManager.deviceList.values
        val exactMatch = devices.firstOrNull { it.deviceName == portName }
        if (exactMatch != null) {
            return exactMatch
        }

        val normalizedName = portName.substringBefore(" - ").trim()
        return devices.firstOrNull { it.deviceName == normalizedName }
    }

    private fun openUsbDevice(
        device: UsbDevice,
        baudRate: Int,
        result: MethodChannel.Result,
    ) {
        usbIoExecutor.execute {
            try {
                closeUsbConnection()

                val config = resolvePortConfig(device)
                if (config == null) {
                    mainHandler.post {
                        result.error(
                            "usb_driver_missing",
                            null,
                            null,
                        )
                    }
                    return@execute
                }

                val connection = usbManager.openDevice(device)
                if (connection == null) {
                    mainHandler.post {
                        result.error(
                            "usb_open_failed",
                            null,
                            null,
                        )
                    }
                    return@execute
                }

                if (!connection.claimInterface(config.dataInterface, true)) {
                    connection.close()
                    mainHandler.post {
                        result.error(
                            "usb_open_failed",
                            null,
                            null,
                        )
                    }
                    return@execute
                }

                if (config.controlInterface != null &&
                    config.controlInterface.id != config.dataInterface.id &&
                    !connection.claimInterface(config.controlInterface, true)
                ) {
                    connection.releaseInterface(config.dataInterface)
                    connection.close()
                    mainHandler.post {
                        result.error(
                            "usb_open_failed",
                            null,
                            null,
                        )
                    }
                    return@execute
                }

                usbConnection = connection
                usbInEndpoint = config.inEndpoint
                usbOutEndpoint = config.outEndpoint
                controlInterface = config.controlInterface
                dataInterface = config.dataInterface

                configureDevice(connection, config, baudRate)

                connectedDeviceName = device.deviceName
                startReadLoop()

                mainHandler.post {
                    result.success(null)
                }
            } catch (error: Exception) {
                closeUsbConnection()
                mainHandler.post {
                    result.error("usb_connect_failed", error.message, null)
                }
            }
        }
    }

    private fun resolvePortConfig(device: UsbDevice): PortConfig? {
        var preferredDataInterface: UsbInterface? = null
        var preferredInEndpoint: UsbEndpoint? = null
        var preferredOutEndpoint: UsbEndpoint? = null
        var fallbackDataInterface: UsbInterface? = null
        var fallbackInEndpoint: UsbEndpoint? = null
        var fallbackOutEndpoint: UsbEndpoint? = null
        var preferredControlInterface: UsbInterface? = null

        for (interfaceIndex in 0 until device.interfaceCount) {
            val usbInterface = device.getInterface(interfaceIndex)
            var inEndpoint: UsbEndpoint? = null
            var outEndpoint: UsbEndpoint? = null

            for (endpointIndex in 0 until usbInterface.endpointCount) {
                val endpoint = usbInterface.getEndpoint(endpointIndex)
                if (endpoint.type != UsbConstants.USB_ENDPOINT_XFER_BULK) {
                    continue
                }
                when (endpoint.direction) {
                    UsbConstants.USB_DIR_IN -> if (inEndpoint == null) inEndpoint = endpoint
                    UsbConstants.USB_DIR_OUT -> if (outEndpoint == null) outEndpoint = endpoint
                }
            }

            val hasDataPair = inEndpoint != null && outEndpoint != null
            when {
                usbInterface.interfaceClass == UsbConstants.USB_CLASS_COMM &&
                    preferredControlInterface == null -> {
                    preferredControlInterface = usbInterface
                }
                hasDataPair &&
                    usbInterface.interfaceClass == UsbConstants.USB_CLASS_CDC_DATA -> {
                    preferredDataInterface = usbInterface
                    preferredInEndpoint = inEndpoint
                    preferredOutEndpoint = outEndpoint
                }
                hasDataPair && fallbackDataInterface == null -> {
                    fallbackDataInterface = usbInterface
                    fallbackInEndpoint = inEndpoint
                    fallbackOutEndpoint = outEndpoint
                }
            }
        }

        val dataInterface = preferredDataInterface ?: fallbackDataInterface ?: return null
        val inEndpoint = preferredInEndpoint ?: fallbackInEndpoint ?: return null
        val outEndpoint = preferredOutEndpoint ?: fallbackOutEndpoint ?: return null
        return PortConfig(preferredControlInterface, dataInterface, inEndpoint, outEndpoint)
    }

    private fun configureDevice(
        connection: UsbDeviceConnection,
        config: PortConfig,
        baudRate: Int,
    ) {
        val control = config.controlInterface ?: return
        val lineCoding =
            byteArrayOf(
                (baudRate and 0xFF).toByte(),
                ((baudRate shr 8) and 0xFF).toByte(),
                ((baudRate shr 16) and 0xFF).toByte(),
                ((baudRate shr 24) and 0xFF).toByte(),
                0, // stop bits: 1
                0, // parity: none
                8, // data bits
            )

                val lineCodingResult =
            connection.controlTransfer(
                UsbConstants.USB_DIR_OUT or
                    UsbConstants.USB_TYPE_CLASS or
                    usbRecipientInterface,
                0x20,
                0,
                control.id,
                lineCoding,
                lineCoding.size,
                1000,
            )
        if (lineCodingResult < 0) {
            throw IllegalStateException("Failed to configure USB line coding")
        }

        val controlLineResult =
            connection.controlTransfer(
                UsbConstants.USB_DIR_OUT or
                    UsbConstants.USB_TYPE_CLASS or
                    usbRecipientInterface,
                0x22,
                0x0001, // DTR on, RTS off
                control.id,
                null,
                0,
                1000,
            )
        if (controlLineResult < 0) {
            throw IllegalStateException("Failed to configure USB control line state")
        }
    }

    private fun startReadLoop() {
        val connection = usbConnection ?: return
        val endpoint = usbInEndpoint ?: return

        isReading = true
        readThread =
            Thread({
                val packetSize = endpoint.maxPacketSize.coerceAtLeast(64)
                val buffer = ByteArray(packetSize * 4)
                try {
                    while (isReading) {
                        val bytesRead = connection.bulkTransfer(endpoint, buffer, buffer.size, 250)
                        if (!isReading) {
                            break
                        }
                        if (bytesRead <= 0) {
                            continue
                        }
                        val packet = buffer.copyOf(bytesRead)
                        mainHandler.post {
                            eventSink?.success(packet)
                        }
                    }
                } catch (error: Exception) {
                    if (isReading) {
                        mainHandler.post {
                            eventSink?.error(
                                "usb_io_error",
                                error.message ?: "USB serial I/O error",
                                null,
                            )
                        }
                        scheduleCloseUsbConnection()
                    }
                }
            }, "MeshCoreUsbRead").also { thread ->
                thread.isDaemon = true
                thread.start()
            }
    }

    private fun writeToDevice(data: ByteArray) {
        val connection = usbConnection ?: throw IllegalStateException("USB connection missing")
        val endpoint = usbOutEndpoint ?: throw IllegalStateException("USB output endpoint missing")
        var offset = 0
        val maxPacketSize = endpoint.maxPacketSize.coerceAtLeast(64)
        while (offset < data.size) {
            val chunkSize = minOf(maxPacketSize, data.size - offset)
            val chunk = data.copyOfRange(offset, offset + chunkSize)
            val bytesWritten = connection.bulkTransfer(endpoint, chunk, chunkSize, 1000)
            if (bytesWritten != chunkSize) {
                throw IllegalStateException("Short USB write: wrote $bytesWritten of $chunkSize bytes")
            }
            offset += chunkSize
        }
    }

    private fun scheduleCloseUsbConnection(onComplete: (() -> Unit)? = null) {
        usbIoExecutor.execute {
            closeUsbConnection()
            if (onComplete != null) {
                mainHandler.post(onComplete)
            }
        }
    }

    @Synchronized
    private fun closeUsbConnection() {
        isReading = false
        readThread?.interrupt()
        if (readThread != null && readThread !== Thread.currentThread()) {
            try {
                readThread?.join(300)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
            }
        }
        readThread = null

        val connection = usbConnection
        val claimedControl = controlInterface
        val claimedData = dataInterface

        usbInEndpoint = null
        usbOutEndpoint = null
        controlInterface = null
        dataInterface = null
        usbConnection = null

        if (connection != null) {
            if (claimedControl != null) {
                try {
                    connection.releaseInterface(claimedControl)
                } catch (_: Exception) {
                }
            }
            if (claimedData != null && claimedData.id != claimedControl?.id) {
                try {
                    connection.releaseInterface(claimedData)
                } catch (_: Exception) {
                }
            }
            try {
                connection.close()
            } catch (_: Exception) {
            }
        }
        connectedDeviceName = null
    }

    private fun handleUsbDetached(intent: Intent) {
        val detachedDevice =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
            }

        val detachedName = detachedDevice?.deviceName ?: return

        if (pendingConnectPortName == detachedName) {
            pendingConnectResult?.error(
                "usb_device_detached",
                "USB device was removed before the connection completed",
                null,
            )
            pendingConnectResult = null
            pendingConnectPortName = null
        }

        if (connectedDeviceName == detachedName) {
            scheduleCloseUsbConnection {
                eventSink?.error(
                    "usb_device_detached",
                    "USB device was disconnected",
                    null,
                )
            }
        }
    }

    private fun pendingIntentFlags(): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = flags or PendingIntent.FLAG_MUTABLE
        }
        return flags
    }
}
