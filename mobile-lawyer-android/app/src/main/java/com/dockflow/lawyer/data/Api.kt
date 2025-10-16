package com.dockflow.lawyer.data

import com.squareup.moshi.JsonClass
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.Path

@JsonClass(generateAdapter = true)
data class LoginRequest(val email: String, val password: String)
@JsonClass(generateAdapter = true)
data class User(val id: Long, val email: String, val role: String?, val full_name: String?)
@JsonClass(generateAdapter = true)
data class LoginResponse(val token: String, val user: User)

@JsonClass(generateAdapter = true)
data class Chat(val id: Long, val visitor_id: String?, val created_at: String)
@JsonClass(generateAdapter = true)
data class Message(val id: Long?, val sender: String, val text: String, val created_at: String?)
@JsonClass(generateAdapter = true)
data class SendMessageRequest(val sender: String, val text: String)

interface ApiService {
    @POST("/api/auth/login")
    suspend fun login(@Body body: LoginRequest): LoginResponse

    @GET("/api/chats")
    suspend fun listChats(@Header("Authorization") bearer: String): List<Chat>

    @GET("/api/chats/{chatId}/messages")
    suspend fun listMessages(@Header("Authorization") bearer: String, @Path("chatId") chatId: Long): List<Message>

    @POST("/api/chats/{chatId}/messages")
    suspend fun sendMessage(@Path("chatId") chatId: Long, @Body body: SendMessageRequest): MessageIdResponse
}

@JsonClass(generateAdapter = true)
data class MessageIdResponse(val id: Long, val created_at: String)

object ApiClientFactory {
    fun create(baseUrl: String): ApiService {
        val retrofit = Retrofit.Builder()
            .baseUrl(baseUrl)
            .addConverterFactory(MoshiConverterFactory.create())
            .build()
        return retrofit.create(ApiService::class.java)
    }
}


