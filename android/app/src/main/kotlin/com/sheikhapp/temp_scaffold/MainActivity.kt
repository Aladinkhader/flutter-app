package com.sheikhapp.temp_scaffold

import android.content.Intent
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val CHANNEL = "com.sheikhapp.temp_scaffold/native_media"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "nativePlay" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.error("INVALID_URL", "رابط الصوت فارغ", null)
                        return@setMethodCallHandler
                    }

                    val intent = Intent(this, NativeMediaPlaybackService::class.java).apply {
                        action = NativeMediaPlaybackService.ACTION_PLAY
                        putExtra(NativeMediaPlaybackService.EXTRA_URL, url)
                        putExtra(
                            NativeMediaPlaybackService.EXTRA_TITLE,
                            call.argument<String>("title").orEmpty(),
                        )
                        putExtra(
                            NativeMediaPlaybackService.EXTRA_ARTIST,
                            call.argument<String>("artist").orEmpty(),
                        )
                    }

                    ContextCompat.startForegroundService(this, intent)
                    result.success(true)
                }

                "nativePause" -> {
                    sendNativeAction(NativeMediaPlaybackService.ACTION_PAUSE)
                    result.success(true)
                }

                "nativeStop" -> {
                    sendNativeAction(NativeMediaPlaybackService.ACTION_STOP)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun sendNativeAction(action: String) {
        val intent = Intent(this, NativeMediaPlaybackService::class.java).apply {
            this.action = action
        }
        ContextCompat.startForegroundService(this, intent)
    }
}
