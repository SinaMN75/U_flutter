package com.sinamn75.u.ble

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.ArrayDeque
import java.util.UUID

/**
 * Native side of UBle ("u/ble" + scan / events): BluetoothLeScanner and BluetoothGatt.
 * GATT allows one operation at a time per device, so writes and descriptor writes queue per connection.
 * The app declares the permissions (`dart run u:app permission add bluetooth`); the plugin declares none.
 */
@SuppressLint("MissingPermission")
class UBleHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener {
    private val channel = MethodChannel(messenger, "u/ble")
    private val scanChannel = EventChannel(messenger, "u/ble/scan")
    private val eventsChannel = EventChannel(messenger, "u/ble/events")
    private val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val main = Handler(Looper.getMainLooper())
    private val links = HashMap<String, Link>()
    private var binding: ActivityPluginBinding? = null
    private var pendingPermission: MethodChannel.Result? = null
    private var scanSink: EventChannel.EventSink? = null
    private var eventsSink: EventChannel.EventSink? = null
    private var scanning = false

    private val adapter: BluetoothAdapter? get() = manager?.adapter

    private class Operation(val run: () -> Boolean, val result: MethodChannel.Result)

    private class Link(val id: String) {
        var gatt: BluetoothGatt? = null
        var connect: MethodChannel.Result? = null
        var mtu = 23
        val queue = ArrayDeque<Operation>()
        var running: Operation? = null

        fun enqueue(operation: Operation) {
            queue.add(operation)
            if (running == null) next()
        }

        fun next() {
            running = null
            while (queue.isNotEmpty()) {
                val operation = queue.poll() ?: return
                running = operation
                if (runCatching { operation.run() }.getOrDefault(false)) return
                running = null
                operation.result.error("failed", "operation could not start", null)
            }
        }

        fun finish(ok: Boolean) {
            val operation = running ?: return
            if (ok) operation.result.success(null) else operation.result.error("failed", null, null)
            next()
        }

        fun fail(code: String) {
            connect?.error(code, null, null)
            connect = null
            running?.result?.error("disconnected", null, null)
            running = null
            while (queue.isNotEmpty()) queue.poll()?.result?.error("disconnected", null, null)
        }
    }

    init {
        channel.setMethodCallHandler(this)
        scanChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    scanSink = events
                }

                override fun onCancel(arguments: Any?) {
                    scanSink = null
                }
            },
        )
        eventsChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventsSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventsSink = null
                }
            },
        )
    }

    fun attach(binding: ActivityPluginBinding) {
        detach()
        this.binding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    fun detach() {
        binding?.removeRequestPermissionsResultListener(this)
        binding = null
    }

    fun dispose() {
        detach()
        stopScan()
        links.values.forEach { runCatching { it.gatt?.close() } }
        links.clear()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "state" -> result.success(state())
                "requestPermission" -> requestPermission(result)
                "startScan" -> startScan(call.argument<List<String>>("services") ?: emptyList(), result)
                "stopScan" -> {
                    stopScan()
                    result.success(null)
                }

                "connect" -> connect(call.argument<String>("id") ?: "", (call.argument<Number>("timeout") ?: 15000).toLong(), result)
                "disconnect" -> {
                    links[call.argument<String>("id") ?: ""]?.gatt?.disconnect()
                    result.success(null)
                }

                "setNotify" -> setNotify(call, result)
                "write" -> write(call, result)
                else -> result.notImplemented()
            }
        } catch (e: SecurityException) {
            result.error("unauthorized", e.message, null)
        } catch (e: Exception) {
            result.error("failed", e.message, null)
        }
    }

    private val permissions: Array<String>
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        else arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)

    private fun granted(): Boolean = permissions.all { context.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED }

    private fun state(): String {
        val adapter = adapter ?: return "unsupported"
        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) return "unsupported"
        if (!granted()) return "unauthorized"
        return if (adapter.isEnabled) "poweredOn" else "poweredOff"
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val activity = binding?.activity
        if (granted() || activity == null) return result.success(state())
        pendingPermission?.success(state())
        pendingPermission = result
        activity.requestPermissions(permissions, REQUEST_PERMISSION)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_PERMISSION) return false
        pendingPermission?.success(state())
        pendingPermission = null
        return true
    }

    private fun startScan(services: List<String>, result: MethodChannel.Result) {
        val code = state()
        if (code != "poweredOn") return result.error(code, null, null)
        val scanner = adapter?.bluetoothLeScanner ?: return result.error("poweredOff", null, null)
        stopScan()
        val filters = services.map { ScanFilter.Builder().setServiceUuid(ParcelUuid(UUID.fromString(it))).build() }
        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()
        scanner.startScan(filters, settings, scanCallback)
        scanning = true
        result.success(null)
    }

    private fun stopScan() {
        if (!scanning) return
        scanning = false
        runCatching { adapter?.bluetoothLeScanner?.stopScan(scanCallback) }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val record = result.scanRecord
            val manufacturer = HashMap<Int, ByteArray>()
            record?.manufacturerSpecificData?.let { data -> for (i in 0 until data.size()) manufacturer[data.keyAt(i)] = data.valueAt(i) }
            val device = mapOf(
                "id" to result.device.address,
                "name" to (record?.deviceName ?: runCatching { result.device.name }.getOrNull() ?: ""),
                "rssi" to result.rssi,
                "services" to (record?.serviceUuids?.map { it.uuid.toString() } ?: emptyList()),
                "manufacturerData" to manufacturer,
            )
            main.post { scanSink?.success(device) }
        }

        override fun onScanFailed(errorCode: Int) {
            scanning = false
            main.post { scanSink?.error("failed", "scan failed: $errorCode", null) }
        }
    }

    private fun connect(id: String, timeout: Long, result: MethodChannel.Result) {
        val code = state()
        if (code != "poweredOn") return result.error(code, null, null)
        if (!BluetoothAdapter.checkBluetoothAddress(id)) return result.error("notFound", null, null)
        links.remove(id)?.let { runCatching { it.gatt?.close() } }
        val link = Link(id)
        link.connect = result
        links[id] = link
        val device = adapter!!.getRemoteDevice(id)
        link.gatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) device.connectGatt(context, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
        else device.connectGatt(context, false, gattCallback)
        main.postDelayed({
            if (link.connect != null) {
                link.fail("timeout")
                runCatching { link.gatt?.close() }
                links.remove(id)
            }
        }, timeout)
    }

    private fun characteristic(link: Link, call: MethodCall): BluetoothGattCharacteristic? =
        link.gatt?.getService(UUID.fromString(call.argument<String>("service")))?.getCharacteristic(UUID.fromString(call.argument<String>("characteristic")))

    private fun setNotify(call: MethodCall, result: MethodChannel.Result) {
        val link = links[call.argument<String>("id") ?: ""] ?: return result.error("disconnected", null, null)
        val target = characteristic(link, call) ?: return result.error("notFound", null, null)
        val enable = call.argument<Boolean>("enable") == true
        val gatt = link.gatt ?: return result.error("disconnected", null, null)
        if (!gatt.setCharacteristicNotification(target, enable)) return result.error("failed", null, null)
        val descriptor = target.getDescriptor(CCCD) ?: return result.success(null)
        val value = if (!enable) BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
        else if (target.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0 && target.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY == 0) BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
        else BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        link.enqueue(
            Operation({
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) gatt.writeDescriptor(descriptor, value) == 0
                else {
                    @Suppress("DEPRECATION")
                    descriptor.value = value
                    @Suppress("DEPRECATION")
                    gatt.writeDescriptor(descriptor)
                }
            }, result),
        )
    }

    private fun write(call: MethodCall, result: MethodChannel.Result) {
        val link = links[call.argument<String>("id") ?: ""] ?: return result.error("disconnected", null, null)
        val target = characteristic(link, call) ?: return result.error("notFound", null, null)
        val value = call.argument<ByteArray>("value") ?: ByteArray(0)
        val type = if (call.argument<Boolean>("withResponse") == false) BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE else BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        val gatt = link.gatt ?: return result.error("disconnected", null, null)
        link.enqueue(
            Operation({
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) gatt.writeCharacteristic(target, value, type) == 0
                else {
                    @Suppress("DEPRECATION")
                    target.value = value
                    target.writeType = type
                    @Suppress("DEPRECATION")
                    gatt.writeCharacteristic(target)
                }
            }, result),
        )
    }

    private fun emitValue(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray) {
        val event = mapOf(
            "event" to "value",
            "id" to gatt.device.address,
            "service" to characteristic.service.uuid.toString(),
            "characteristic" to characteristic.uuid.toString(),
            "value" to value,
        )
        main.post { eventsSink?.success(event) }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            main.post {
                val link = links[gatt.device.address] ?: return@post
                if (newState == BluetoothProfile.STATE_CONNECTED && status == BluetoothGatt.GATT_SUCCESS) {
                    if (!gatt.discoverServices()) link.fail("failed")
                    return@post
                }
                val wasConnecting = link.connect != null
                link.fail("failed")
                runCatching { gatt.close() }
                links.remove(gatt.device.address)
                if (!wasConnecting) eventsSink?.success(mapOf("event" to "disconnected", "id" to gatt.device.address))
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            main.post {
                val link = links[gatt.device.address] ?: return@post
                if (status != BluetoothGatt.GATT_SUCCESS) return@post link.fail("failed")
                if (!gatt.requestMtu(MAX_MTU)) completeConnect(link)
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            main.post {
                val link = links[gatt.device.address] ?: return@post
                if (status == BluetoothGatt.GATT_SUCCESS) link.mtu = mtu
                if (link.connect != null) completeConnect(link) else link.finish(status == BluetoothGatt.GATT_SUCCESS)
            }
        }

        override fun onCharacteristicWrite(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
            main.post { links[gatt.device.address]?.finish(status == BluetoothGatt.GATT_SUCCESS) }
        }

        override fun onDescriptorWrite(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            main.post { links[gatt.device.address]?.finish(status == BluetoothGatt.GATT_SUCCESS) }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray) = emitValue(gatt, characteristic, value)

        @Deprecated("Android 12 and below")
        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) return
            @Suppress("DEPRECATION")
            emitValue(gatt, characteristic, characteristic.value ?: ByteArray(0))
        }
    }

    private fun completeConnect(link: Link) {
        val result = link.connect ?: return
        link.connect = null
        result.success(link.mtu - 3)
    }

    companion object {
        private const val REQUEST_PERMISSION = 0x5542
        private const val MAX_MTU = 517
        private val CCCD: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
}
