package com.example.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareInboxChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "consume") {
                    result.success(ShareInbox.consume(this))
                } else {
                    result.notImplemented()
                }
            }
    }

    companion object {
        private const val shareInboxChannel = "com.example.app/share_inbox"
    }
}
