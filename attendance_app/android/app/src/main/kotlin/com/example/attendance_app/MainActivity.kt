package com.example.attendance_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.attendance_app/permissions"
    private val BLUETOOTH_PERMISSION_REQUEST_CODE = 2001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "requestBluetoothPermissions") {
                    requestBluetoothPermissions(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun requestBluetoothPermissions(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ requires runtime Bluetooth permissions
            val permissionsNeeded = mutableListOf<String>()

            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
                != PackageManager.PERMISSION_GRANTED
            ) {
                permissionsNeeded.add(Manifest.permission.BLUETOOTH_CONNECT)
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN)
                != PackageManager.PERMISSION_GRANTED
            ) {
                permissionsNeeded.add(Manifest.permission.BLUETOOTH_SCAN)
            }

            if (permissionsNeeded.isNotEmpty()) {
                pendingResult = result
                ActivityCompat.requestPermissions(
                    this,
                    permissionsNeeded.toTypedArray(),
                    BLUETOOTH_PERMISSION_REQUEST_CODE
                )
            } else {
                // Already granted
                result.success(true)
            }
        } else {
            // On Android 11 and below, manifest permissions are sufficient
            result.success(true)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == BLUETOOTH_PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.isNotEmpty() &&
                    grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingResult?.success(allGranted)
            pendingResult = null
        }
    }
}
