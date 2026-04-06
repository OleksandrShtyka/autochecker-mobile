package com.autochecker.autochecker_mobile

import android.accounts.AccountManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "autochecker/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceInfo" -> {
                        val isSamsung = Build.MANUFACTURER.lowercase() == "samsung"
                        val samsungEmail: String? = if (isSamsung) {
                            try {
                                val am = AccountManager.get(this)
                                val accounts = am.getAccountsByType("com.osp.app.signin")
                                accounts.firstOrNull()?.name
                            } catch (_: Exception) {
                                null
                            }
                        } else null

                        result.success(mapOf(
                            "isSamsung" to isSamsung,
                            "samsungEmail" to samsungEmail,
                            "model" to Build.MODEL,
                        ))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
