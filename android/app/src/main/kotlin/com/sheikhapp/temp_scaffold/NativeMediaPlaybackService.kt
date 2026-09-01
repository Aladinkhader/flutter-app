package com.sheikhapp.temp_scaffold

import android.app.PendingIntent
import android.content.Intent
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService

@UnstableApi
class NativeMediaPlaybackService : MediaSessionService() {

    companion object {
        const val ACTION_PLAY = "com.sheikhapp.temp_scaffold.PLAY"
        const val ACTION_PAUSE = "com.sheikhapp.temp_scaffold.PAUSE"
        const val ACTION_STOP = "com.sheikhapp.temp_scaffold.STOP"

        const val EXTRA_URL = "audio_url"
        const val EXTRA_TITLE = "audio_title"
        const val EXTRA_ARTIST = "audio_artist"
    }

    private var player: ExoPlayer? = null
    private var mediaSession: MediaSession? = null

    override fun onCreate() {
        super.onCreate()

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags =
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val sessionActivity = PendingIntent.getActivity(
            this,
            100,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE,
        )

        val audioPlayer = ExoPlayer.Builder(this)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_SPEECH)
                    .build(),
                true,
            )
            .setHandleAudioBecomingNoisy(true)
            .build()

        player = audioPlayer

        mediaSession = MediaSession.Builder(this, audioPlayer)
            .setSessionActivity(sessionActivity)
            .build()
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int,
    ): Int {

        when (intent?.action) {

            ACTION_PLAY -> {
                val url = intent.getStringExtra(EXTRA_URL)

                if (!url.isNullOrBlank()) {

                    val title =
                        intent.getStringExtra(EXTRA_TITLE).orEmpty()

                    val artist =
                        intent.getStringExtra(EXTRA_ARTIST).orEmpty()

                    val item = MediaItem.Builder()
                        .setUri(url)
                        .setMediaMetadata(
                            MediaMetadata.Builder()
                                .setTitle(title)
                                .setArtist(artist)
                                .setAlbumTitle(
                                    "الشيخ د. محمد الأمين إسماعيل"
                                )
                                .build()
                        )
                        .build()

                    player?.setMediaItem(item)
                    player?.prepare()
                    player?.play()
                }
            }

            ACTION_PAUSE -> {
                player?.pause()
            }

            ACTION_STOP -> {
                player?.stop()
                player?.clearMediaItems()
                stopSelf()
            }
        }

        return START_STICKY
    }

    override fun onGetSession(
        controllerInfo: MediaSession.ControllerInfo,
    ): MediaSession? = mediaSession

    override fun onDestroy() {
        mediaSession?.release()
        mediaSession = null

        player?.release()
        player = null

        super.onDestroy()
    }
}
