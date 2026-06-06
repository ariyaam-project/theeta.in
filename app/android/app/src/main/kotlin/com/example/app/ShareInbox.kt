package com.example.app

import android.content.Context

object ShareInbox {
    private const val preferencesName = "theta_share_inbox"
    private const val pendingUrlsKey = "pending_urls"

    fun add(context: Context, value: String) {
        val preferences =
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val pending = preferences.getStringSet(pendingUrlsKey, emptySet()).orEmpty().toMutableSet()
        pending.add(value)
        preferences.edit().putStringSet(pendingUrlsKey, pending).apply()
    }

    fun consume(context: Context): List<String> {
        val preferences =
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val pending = preferences.getStringSet(pendingUrlsKey, emptySet()).orEmpty().toList()
        preferences.edit().remove(pendingUrlsKey).apply()
        return pending
    }
}
