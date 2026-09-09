package com.sinamn75.u.media

import android.content.Intent
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService

@UnstableApi
class UMediaService : MediaSessionService() {
    companion object {
        private val sessions = linkedMapOf<Int, MediaSession>()

        fun register(
            id: Int,
            session: MediaSession,
        ) {
            sessions[id] = session
        }

        fun unregister(id: Int) {
            sessions.remove(id)
        }

        fun current(): MediaSession? = sessions.values.lastOrNull()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? = current()

    override fun onTaskRemoved(rootIntent: Intent?) {
        val session = current()
        if (session == null || !session.player.playWhenReady || session.player.mediaItemCount == 0) {
            stopSelf()
        }
        super.onTaskRemoved(rootIntent)
    }
}
