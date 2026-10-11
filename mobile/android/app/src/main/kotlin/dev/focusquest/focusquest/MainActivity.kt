package dev.focusquest.focusquest

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private fun hasUsageAccess(): Boolean {
        val ops = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= 29)
            ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        else ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        return mode == AppOpsManager.MODE_ALLOWED
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.focusquest/usage")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "guardPermissions" -> result.success(mapOf(
                            "usage" to hasUsageAccess(),
                            "overlay" to (Build.VERSION.SDK_INT < 23 || Settings.canDrawOverlays(this))))
                        "requestOverlay" -> {
                            if (Build.VERSION.SDK_INT >= 23) startActivity(Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                            result.success(null)
                        }
                        "startGuard" -> {
                            check(hasUsageAccess() && (Build.VERSION.SDK_INT < 23 || Settings.canDrawOverlays(this)))
                            val intent = Intent(this, FocusGuardService::class.java)
                                .putExtra("sessionId", call.argument<String>("id"))
                                .putExtra("endsAt", call.argument<Number>("endsAt")!!.toLong())
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
                            result.success(null)
                        }
                        "stopGuard" -> {
                            stopService(Intent(this, FocusGuardService::class.java))
                            getSharedPreferences("focus_guard", MODE_PRIVATE).edit().clear().apply()
                            result.success(null)
                        }
                        "hasAccess" -> result.success(hasUsageAccess())
                        "requestAccess" -> {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                            result.success(null)
                        }
                        "apps" -> {
                            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                            val apps = packageManager.queryIntentActivities(intent, 0)
                                .filter { it.activityInfo.packageName != packageName }
                                .distinctBy { it.activityInfo.packageName }
                                .map { mapOf("package" to it.activityInfo.packageName,
                                    "name" to it.loadLabel(packageManager).toString()) }
                                .sortedBy { it["name"] }
                            result.success(apps)
                        }
                        "evidence" -> {
                            if (!hasUsageAccess()) {
                                result.success(mapOf("available" to false, "targetUsed" to false))
                            } else {
                                val start = call.argument<Number>("start")!!.toLong()
                                val end = call.argument<Number>("end")!!.toLong()
                                val targets = call.argument<List<String>>("packages")!!.toSet()
                                require(end >= start && start > 0 && end <= System.currentTimeMillis() + 1000)
                                val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                                val events = manager.queryEvents(start - 86400000L, end)
                                if (events == null) {
                                    result.success(mapOf("available" to false, "targetUsed" to false))
                                } else {
                                    val event = UsageEvents.Event()
                                    val resumed = mutableSetOf<String>()
                                    var used = false
                                    var hasBaseline = false
                                    var crossedStart = false
                                    while (events.hasNextEvent()) {
                                        events.getNextEvent(event)
                                        hasBaseline = true
                                        if (event.timeStamp >= start && !crossedStart) {
                                            used = resumed.any { it in targets }
                                            crossedStart = true
                                        }
                                        if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                                            resumed.add(event.packageName)
                                            if (event.timeStamp >= start && event.packageName in targets) used = true
                                        } else if (event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                                            resumed.remove(event.packageName)
                                        }
                                    }
                                    if (!crossedStart) used = resumed.any { it in targets }
                                    // A pre-session foreground event also establishes the baseline
                                    // when the user stays in FQ for the entire session.
                                    result.success(mapOf("available" to hasBaseline, "targetUsed" to used))
                                }
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("USAGE_UNAVAILABLE", "使用状況を取得できませんでした。", null)
                }
            }
    }
}
