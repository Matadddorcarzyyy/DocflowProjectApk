package com.dockflow.lawyer.ui

import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.dockflow.lawyer.data.ApiClientFactory
import com.dockflow.lawyer.data.AuthStore
import com.dockflow.lawyer.data.Message
import com.dockflow.lawyer.data.SendMessageRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ChatActivity : ComponentActivity() {
    private val api by lazy { ApiClientFactory.create("http://10.0.2.2:8080") }
    private lateinit var auth: AuthStore
    private var chatId: Long = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        chatId = intent.getLongExtra("chatId", 0)
        auth = AuthStore(this)

        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        val scroll = ScrollView(this)
        val messagesView = TextView(this)
        scroll.addView(messagesView)
        val input = EditText(this)
        val send = Button(this).apply { text = "Отправить" }
        root.addView(scroll, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))
        root.addView(input)
        root.addView(send)
        setContentView(root)

        val token = auth.getToken()
        if (token == null || chatId == 0L) {
            Toast.makeText(this, "Нет токена или неверный чат", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        lifecycleScope.launch {
            try {
                val items = withContext(Dispatchers.IO) {
                    api.listMessages("Bearer $token", chatId)
                }
                messagesView.text = items.joinToString("\n") { formatMessage(it) }
            } catch (e: Exception) {
                Toast.makeText(this@ChatActivity, "Ошибка сообщений: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }

        send.setOnClickListener {
            val text = input.text.toString().trim()
            if (text.isEmpty()) return@setOnClickListener
            lifecycleScope.launch {
                try {
                    withContext(Dispatchers.IO) {
                        api.sendMessage(chatId, SendMessageRequest(sender = "lawyer", text = text))
                    }
                    // locally append
                    val current = messagesView.text.toString()
                    messagesView.text = if (current.isEmpty()) "Вы: $text" else current + "\n" + "Вы: $text"
                    input.text.clear()
                } catch (e: Exception) {
                    Toast.makeText(this@ChatActivity, "Ошибка отправки: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun formatMessage(m: Message): String {
        val who = when (m.sender) {
            "lawyer" -> "Вы"
            "visitor" -> "Клиент"
            "ai" -> "ИИ"
            else -> m.sender
        }
        return "$who: ${m.text}"
    }
}


