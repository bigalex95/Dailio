package com.example.dailio

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "dailio/foreground_app"
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getForegroundApp" -> getForegroundApp(result)
                "checkPermissions" -> checkUsageStatsPermission(result)
                "requestPermissions" -> requestUsageStatsPermission(result)
                "getPlatformInfo" -> getPlatformInfo(result)
                "test" -> result.success("success")
                else -> result.notImplemented()
            }
        }
    }

    private fun getForegroundApp(result: MethodChannel.Result) {
        try {
            if (!hasUsageStatsPermission()) {
                result.error("NO_PERMISSIONS", "Usage access permission required", 
                    "Please grant usage access permission in Settings > Apps > Special access > Usage access")
                return
            }

            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val currentTime = System.currentTimeMillis()
            
            // Query recent usage events (last 10 seconds)
            val usageEvents = usageStatsManager.queryEvents(currentTime - 10000, currentTime)
            
            var lastAppPackage: String? = null
            var lastEventTime = 0L
            
            val event = UsageEvents.Event()
            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                
                // Look for the most recent foreground event
                if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND && 
                    event.timeStamp > lastEventTime) {
                    lastEventTime = event.timeStamp
                    lastAppPackage = event.packageName
                }
            }
            
            if (lastAppPackage != null) {
                val appName = getAppName(lastAppPackage)
                result.success(appName)
            } else {
                result.error("NO_APP", "Could not detect foreground app", null)
            }
            
        } catch (e: Exception) {
            result.error("DETECTION_FAILED", "Failed to detect foreground app: ${e.message}", null)
        }
    }

    private fun getAppName(packageName: String): String {
        return try {
            val packageManager = applicationContext.packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            // If we can't get the app name, return the package name
            packageName
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        return try {
            val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOpsManager.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOpsManager.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    private fun checkUsageStatsPermission(result: MethodChannel.Result) {
        result.success(hasUsageStatsPermission())
    }

    private fun requestUsageStatsPermission(result: MethodChannel.Result) {
        try {
            if (hasUsageStatsPermission()) {
                result.success(false) // Already has permission
                return
            }

            // Open usage access settings
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            startActivity(intent)
            result.success(true) // User should check settings
        } catch (e: Exception) {
            result.error("REQUEST_FAILED", "Failed to request permission: ${e.message}", null)
        }
    }

    private fun getPlatformInfo(result: MethodChannel.Result) {
        val info = mapOf(
            "platform" to "Android",
            "supported" to true,
            "version" to "${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
            "hasPermissions" to hasUsageStatsPermission(),
            "requiresPermissions" to true,
            "permissionsLocation" to "Settings > Apps > Special access > Usage access"
        )
        result.success(info)
    }
}
