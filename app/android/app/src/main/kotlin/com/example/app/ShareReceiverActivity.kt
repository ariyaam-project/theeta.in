package com.example.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

class ShareReceiverActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val sharedText = if (intent?.action == Intent.ACTION_SEND) {
            intent.getStringExtra(Intent.EXTRA_TEXT)
        } else {
            null
        }

        if (!sharedText.isNullOrBlank() && instagramRegex.containsMatchIn(sharedText)) {
            ShareInbox.add(this, sharedText)
            Toast.makeText(this, "Reel saved to Theta", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(this, "No Instagram reel link found", Toast.LENGTH_SHORT).show()
        }

        finish()
    }

    companion object {
        private val instagramRegex = Regex(
            """https?://(?:www\.)?instagram\.com/(?:reel|reels|p|tv)/[A-Za-z0-9_-]+""",
            RegexOption.IGNORE_CASE,
        )
    }
}
