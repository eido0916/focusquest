package dev.focusquest.focusquest

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.*
import android.provider.Settings
import android.view.*
import android.widget.*

/** Monitors only while a user-started focus session is active. No usage data leaves the device. */
class FocusGuardService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val prefs by lazy { getSharedPreferences("focus_guard", MODE_PRIVATE) }
    private val windows by lazy { getSystemService(Context.WINDOW_SERVICE) as WindowManager }
    private var overlay: View? = null
    private var foreground: String? = null
    private var cursor = 0L
    private val allowance = FocusAllowance()
    private var returning = false
    private val poll = object : Runnable {
        override fun run() {
            if (System.currentTimeMillis() >= prefs.getLong("endsAt", 0L) ||
                (Build.VERSION.SDK_INT >= 23 && !Settings.canDrawOverlays(this@FocusGuardService))) {
                stopSelf(); return
            }
            try {
                val now = System.currentTimeMillis()
                val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val events = manager.queryEvents(cursor, now)
                val event = UsageEvents.Event()
                while (events != null && events.hasNextEvent()) {
                    events.getNextEvent(event)
                    cursor = maxOf(cursor, event.timeStamp + 1L)
                    if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                        foreground = event.packageName
                        returning = false
                    } else if (event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND && foreground == event.packageName) {
                        foreground = null
                    }
                }
                val power = getSystemService(Context.POWER_SERVICE) as PowerManager
                val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                val other = foreground
                val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
                val launcher = packageManager.resolveActivity(home, 0)?.activityInfo?.packageName
                // Home, lock screen and system UI are navigation surfaces, not opened apps.
                val warn = power.isInteractive && !keyguard.isKeyguardLocked && !returning &&
                    other != null && other != packageName && other != launcher && other != "com.android.systemui" &&
                    !allowance.permits(other, SystemClock.elapsedRealtime())
                if (warn) showWarning() else hideWarning()
            } catch (_: Exception) {
                // Revoked usage/overlay access must never crash or trap the user.
                hideWarning()
            }
            handler.postDelayed(this, 350L)
        }
    }

    override fun onBind(intent: Intent?) = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val id = intent?.getStringExtra("sessionId")
        if (id != null && id != prefs.getString("sessionId", null)) {
            prefs.edit().clear().putString("sessionId", id)
                .putLong("endsAt", intent.getLongExtra("endsAt", 0L)).apply()
        }
        // Wall-clock deadline survives service recreation; elapsed time governs a running allowance.
        val remaining = (prefs.getLong("graceEndsAt", 0L) - System.currentTimeMillis()).coerceIn(0L, 60000L)
        allowance.allow(prefs.getString("gracePackage", null), SystemClock.elapsedRealtime(), remaining)
        if (System.currentTimeMillis() >= prefs.getLong("endsAt", 0L)) {
            stopSelf(); return START_NOT_STICKY
        }
        val notifications = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) notifications.createNotificationChannel(
            NotificationChannel("focus_guard", "集中中のアプリ警告", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, "focus_guard") else Notification.Builder(this)
        startForeground(41, builder.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("Focus Quest：集中中")
            .setContentText("他のアプリを開くと警告します。タップして戻る")
            .setContentIntent(open).setOngoing(true).build())
        foreground = if (intent == null) null else packageName
        cursor = System.currentTimeMillis() - if (intent == null) 86400000L else 1000L
        handler.removeCallbacks(poll)
        handler.post(poll)
        return START_STICKY
    }

    private fun showWarning() {
        if (overlay != null) return
        val panel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(28), dp(24), dp(28), dp(24))
            setBackgroundColor(Color.rgb(8, 39, 68))
        }
        fun message(value: String, size: Float) = TextView(this).apply {
            text = value; textSize = size; setTextColor(Color.WHITE)
            gravity = Gravity.CENTER; setPadding(0, dp(12), 0, dp(12))
        }
        panel.addView(message("いまは集中の時間です", 22f))
        panel.addView(message("他のアプリを開いています。\nFocus Questに戻って集中を続けましょう。", 16f))
        panel.addView(Button(this).apply {
            text = "Focus Questに戻る"
            setOnClickListener {
                try {
                    startActivity(Intent(this@FocusGuardService, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP))
                    returning = true
                    hideWarning()
                    handler.postDelayed({ returning = false }, 1500L)
                } catch (_: Exception) { /* Keep both choices available if launching fails. */ }
            }
        }, LinearLayout.LayoutParams(-1, -2))
        panel.addView(Button(this).apply {
            text = "1分だけ使用する"
            setOnClickListener {
                allowance.allow(this@FocusGuardService.foreground, SystemClock.elapsedRealtime())
                prefs.edit().putString("gracePackage", this@FocusGuardService.foreground)
                    .putLong("graceEndsAt", System.currentTimeMillis() + 60000L).apply()
                hideWarning()
            }
        }, LinearLayout.LayoutParams(-1, -2))
        val type = if (Build.VERSION.SDK_INT >= 26) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE
        val backdrop = FrameLayout(this).apply {
            setBackgroundColor(Color.argb(210, 0, 0, 0))
            isClickable = true
            isFocusableInTouchMode = true
            addView(panel, FrameLayout.LayoutParams(-1, -2, Gravity.CENTER).apply {
                leftMargin = dp(20)
                rightMargin = dp(20)
            })
        }
        val params = WindowManager.LayoutParams(-1, -1, type,
            WindowManager.LayoutParams.FLAG_ALT_FOCUSABLE_IM, PixelFormat.TRANSLUCENT).apply {
                gravity = Gravity.CENTER
                softInputMode = WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN
            }
        windows.addView(backdrop, params)
        backdrop.requestFocus()
        overlay = backdrop
    }

    private fun dp(value: Int) = (resources.displayMetrics.density * value).toInt()
    private fun hideWarning() {
        val view = overlay
        overlay = null
        if (view != null) runCatching { windows.removeView(view) }
    }
    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        hideWarning()
        if (System.currentTimeMillis() >= prefs.getLong("endsAt", 0L)) prefs.edit().clear().apply()
        super.onDestroy()
    }
}
