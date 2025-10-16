package com.dockflow.lawyer.ui

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.dockflow.lawyer.data.ApiClientFactory
import com.dockflow.lawyer.data.AuthStore
import com.dockflow.lawyer.databinding.ActivityLoginBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class LoginActivity : ComponentActivity() {
    private lateinit var binding: ActivityLoginBinding
    private lateinit var auth: AuthStore

    private val api by lazy {
        // TODO: replace with your server base URL
        ApiClientFactory.create("http://10.0.2.2:8080")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)
        auth = AuthStore(this)

        binding.btnLogin.setOnClickListener {
            val email = binding.inputEmail.text.toString().trim()
            val pass = binding.inputPassword.text.toString().trim()
            if (email.isEmpty() || pass.isEmpty()) {
                Toast.makeText(this, "Введите email и пароль", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            lifecycleScope.launch {
                try {
                    val r = withContext(Dispatchers.IO) {
                        api.login(com.dockflow.lawyer.data.LoginRequest(email, pass))
                    }
                    if (r.user.role != null && (r.user.role == "lawyer" || r.user.role == "admin" || r.user.role == "owner")) {
                        auth.saveToken(r.token)
                        startActivity(Intent(this@LoginActivity, ChatsActivity::class.java))
                        finish()
                    } else {
                        Toast.makeText(this@LoginActivity, "Нет прав доступа", Toast.LENGTH_SHORT).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(this@LoginActivity, "Ошибка входа: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
}


