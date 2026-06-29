package com.ridehovr.hovr_app_update

internal object VersionCompare {
    fun isUpdateRequired(serverVersion: String, installedVersion: String): Boolean {
        val server = serverVersion.trim()
        if (server.isEmpty()) {
            return false
        }
        return server != installedVersion.trim()
    }
}
