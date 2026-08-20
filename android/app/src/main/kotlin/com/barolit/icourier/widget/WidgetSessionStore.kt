package com.barolit.icourier.widget

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

object WidgetSessionStore {
    private const val preferencesName = "icourier_widget_credentials"
    private const val encryptedSessionKey = "encrypted_session"
    private const val initializationVectorKey = "session_iv"
    private const val keyAlias = "icourier_widget_session_key"

    fun write(context: Context, sessionId: String) {
        if (sessionId.isEmpty()) {
            clear(context)
            return
        }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val encrypted = cipher.doFinal(sessionId.toByteArray(Charsets.UTF_8))
        preferences(context).edit()
            .putString(encryptedSessionKey, Base64.encodeToString(encrypted, Base64.NO_WRAP))
            .putString(
                initializationVectorKey,
                Base64.encodeToString(cipher.iv, Base64.NO_WRAP),
            )
            .commit()
    }

    fun read(context: Context): String? = runCatching {
        val preferences = preferences(context)
        val encrypted = preferences.getString(encryptedSessionKey, null) ?: return null
        val initializationVector =
            preferences.getString(initializationVectorKey, null) ?: return null
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            secretKey(),
            GCMParameterSpec(128, Base64.decode(initializationVector, Base64.NO_WRAP)),
        )
        String(
            cipher.doFinal(Base64.decode(encrypted, Base64.NO_WRAP)),
            Charsets.UTF_8,
        ).takeIf(String::isNotEmpty)
    }.getOrNull()

    fun clear(context: Context) {
        preferences(context).edit().clear().commit()
    }

    private fun preferences(context: Context) = context.getSharedPreferences(
        preferencesName,
        Context.MODE_PRIVATE,
    )

    private fun secretKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getKey(keyAlias, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            "AndroidKeyStore",
        )
        generator.init(
            KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build(),
        )
        return generator.generateKey()
    }
}
