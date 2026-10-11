package dev.focusquest.focusquest

/** Pure per-app allowance policy. Times are monotonic milliseconds while running. */
internal class FocusAllowance {
    var app: String? = null
        private set
    var deadline: Long = 0L
        private set

    fun allow(app: String?, now: Long, duration: Long = 60000L) {
        this.app = app
        deadline = now + duration.coerceIn(0L, 60000L)
    }

    fun permits(app: String?, now: Long): Boolean =
        app != null && app == this.app && now < deadline
}
