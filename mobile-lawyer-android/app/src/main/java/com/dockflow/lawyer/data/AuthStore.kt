package com.dockflow.lawyer.data

import android.content.Context
import android.content.SharedPreferences

class AuthStore(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("lawyer_auth", Context.MODE_PRIVATE)

    fun saveToken(token: String) {
        prefs.edit().putString("token", token).apply()
    }

    fun getToken(): String? = prefs.getString("token", null)

    fun clear() {
        prefs.edit().clear().apply()
    }
}


