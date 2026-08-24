package com.ridehovr.hovr_app_update

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.Process
import kotlin.system.exitProcess

/**
 * Cold-restarts the app so a Shorebird OTA patch can boot.
 *
 * Schedules the launcher activity, then kills this process. Without the
 * relaunch intent, [Process.killProcess] only sends the user to the home
 * screen and the patch never applies until they tap the icon.
 */
internal object ProcessRestarter {
    fun restart(context: Context) {
        val packageName = context.packageName
        val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            val restartIntent = Intent.makeRestartActivityTask(launchIntent.component)
            context.startActivity(restartIntent)
        }

        if (context is Activity) {
            context.finishAffinity()
        }

        // Defer kill so the relaunch intent is delivered first.
        Handler(Looper.getMainLooper()).postDelayed({
            Process.killProcess(Process.myPid())
            exitProcess(0)
        }, 100)
    }
}
