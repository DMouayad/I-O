package com.mouayad_alhamwi.io

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "io.app/device_credential"
    private val confirmRequestCode = 0xC0DE
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            if (call.method == "confirmDeviceCredential") {
                confirmDeviceCredential(
                    call.argument("title"),
                    call.argument("description"),
                    result,
                )
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * PIN/pattern/password prompt via KeyguardManager.
     *
     * Fallback for local_auth on devices without biometric hardware: the
     * plugin throws instead of showing the PIN screen there, while this
     * system intent shows it fine. Cancel maps to success(false) so Dart
     * treats it as a silent dismiss, like the plugin's userCanceled.
     */
    private fun confirmDeviceCredential(
        title: String?,
        description: String?,
        result: MethodChannel.Result,
    ) {
        if (pendingResult != null) {
            result.error("IN_PROGRESS", "Device credential prompt already showing", null)
            return
        }
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (!keyguardManager.isDeviceSecure) {
            result.error("NO_CREDENTIALS", "No PIN, pattern, or password set", null)
            return
        }
        @Suppress("DEPRECATION")
        val intent = keyguardManager.createConfirmDeviceCredentialIntent(title, description)
        if (intent == null) {
            result.error("UNAVAILABLE", "Could not create credential intent", null)
            return
        }
        pendingResult = result
        @Suppress("DEPRECATION")
        startActivityForResult(intent, confirmRequestCode)
    }

    @Deprecated("Legacy result path for the Keyguard confirm intent.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != confirmRequestCode) return
        val result = pendingResult
        pendingResult = null
        if (result == null) return
        result.success(resultCode == Activity.RESULT_OK)
    }
}
