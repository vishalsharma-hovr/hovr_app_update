package com.ridehovr.hovr_app_update

import android.content.Context
import android.util.Log
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class HovrAppUpdatePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private var activity: FragmentActivity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, AppUpdateChannelConstants.CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            AppUpdateChannelConstants.METHOD_CONFIGURE -> handleConfigure(result)
            AppUpdateChannelConstants.METHOD_PROMPT -> handlePrompt(call, result)
            AppUpdateChannelConstants.METHOD_PROMPT_RESTART -> handlePromptRestart(result)
            AppUpdateChannelConstants.METHOD_GET_INSTALLED_VERSION -> handleGetInstalledVersion(result)
            AppUpdateChannelConstants.METHOD_GET_APP_INFO -> handleGetAppInfo(result)
            else -> result.notImplemented()
        }
    }

    private fun handleConfigure(result: Result) {
        result.success(null)
    }

    private fun handleGetInstalledVersion(result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }
        result.success(readInstalledVersion(context))
    }

    private fun handleGetAppInfo(result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        val appInfo = context.applicationInfo
        val appName = appInfo?.let {
            context.packageManager.getApplicationLabel(it).toString()
        } ?: ""
        @Suppress("DEPRECATION")
        val versionCode = packageInfo.versionCode
        result.success(
            mapOf(
                "appName" to appName,
                "packageName" to context.packageName,
                "version" to (packageInfo.versionName ?: ""),
                "buildNumber" to versionCode.toString(),
            )
        )
    }

    private fun handlePrompt(call: MethodCall, result: Result) {
        val serverVersion = readServerVersion(call)
        if (serverVersion == null) {
            result.error("INVALID_ARGS", "serverVersion is required", null)
            return
        }

        val hostActivity = activity
        if (hostActivity == null || hostActivity.isFinishing) {
            result.error("NO_ACTIVITY", "Host activity is not available", null)
            return
        }

        val installedVersion = readInstalledVersion(hostActivity)
        val updateRequired = VersionCompare.isUpdateRequired(serverVersion, installedVersion)
        if (!updateRequired) {
            result.success(promptResult(updateRequired = false, dialogShown = false))
            return
        }

        hostActivity.runOnUiThread {
            val dialogShown = presentUpdateDialogIfNeeded(
                hostActivity,
                AppUpdateChannelConstants.DIALOG_MODE_STORE,
            )
            result.success(promptResult(updateRequired = true, dialogShown = dialogShown))
        }
    }

    private fun handlePromptRestart(result: Result) {
        val hostActivity = activity
        if (hostActivity == null || hostActivity.isFinishing) {
            result.error("NO_ACTIVITY", "Host activity is not available", null)
            return
        }

        hostActivity.runOnUiThread {
            val dialogShown = presentUpdateDialogIfNeeded(
                hostActivity,
                AppUpdateChannelConstants.DIALOG_MODE_RESTART,
            )
            result.success(promptResult(updateRequired = true, dialogShown = dialogShown))
        }
    }

    private fun readServerVersion(call: MethodCall): String? {
        val args = call.arguments as? Map<*, *> ?: return null
        val value = args["serverVersion"] as? String ?: return null
        return value
    }

    private fun readInstalledVersion(context: Context): String {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        return packageInfo.versionName ?: ""
    }

    private fun presentUpdateDialogIfNeeded(
        hostActivity: FragmentActivity,
        mode: String,
    ): Boolean {
        if (updateDialogShownThisSession) {
            return false
        }

        val fragmentManager = hostActivity.supportFragmentManager
        if (fragmentManager.findFragmentByTag(AppUpdateChannelConstants.DIALOG_TAG) != null) {
            return false
        }

        if (hostActivity.isFinishing) {
            return false
        }

        updateDialogShownThisSession = true
        UpdateDialogFragment.newInstance(mode)
            .show(fragmentManager, AppUpdateChannelConstants.DIALOG_TAG)
        Log.d(TAG, "Update dialog presented mode=$mode")
        return true
    }

    private fun promptResult(updateRequired: Boolean, dialogShown: Boolean): Map<String, Boolean> {
        return mapOf(
            "updateRequired" to updateRequired,
            "dialogShown" to dialogShown,
        )
    }

    companion object {
        private const val TAG = "HovrAppUpdate"
        private var updateDialogShownThisSession = false
    }
}
