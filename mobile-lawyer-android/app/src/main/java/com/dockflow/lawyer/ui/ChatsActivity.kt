package com.dockflow.lawyer.ui

import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.dockflow.lawyer.data.ApiClientFactory
import com.dockflow.lawyer.data.AuthStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ChatsActivity : ComponentActivity() {
    private val api by lazy { ApiClientFactory.create("http://10.0.2.2:8080") }
    private lateinit var auth: AuthStore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val listView = ListView(this)
        setContentView(listView)
        auth = AuthStore(this)

        val token = auth.getToken()
        if (token == null) {
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
            return
        }

        lifecycleScope.launch {
            try {
                val chats = withContext(Dispatchers.IO) {
                    api.listChats("Bearer $token")
                }
                val adapter = ArrayAdapter(this@ChatsActivity, android.R.layout.simple_list_item_1, chats.map { "Чат #${it.id}" })
                listView.adapter = adapter
                listView.setOnItemClickListener { _, _, position, _ ->
                    val chat = chats[position]
                    val i = Intent(this@ChatsActivity, ChatActivity::class.java)
                    i.putExtra("chatId", chat.id)
                    startActivity(i)
                }
            } catch (e: Exception) {
                Toast.makeText(this@ChatsActivity, "Ошибка загрузки чатов: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }
}


