package com.sinamn75.u.media

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import android.util.Rational

object UMediaPip {
    fun isSupported(activity: Activity?): Boolean {
        val current = activity ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return current.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    fun enter(
        activity: Activity?,
        aspectRatio: Double,
    ): Boolean {
        val current = activity ?: return false
        if (!isSupported(current)) return false
        val safeRatio = if (aspectRatio.isFinite() && aspectRatio > 0.42 && aspectRatio < 2.38) aspectRatio else 16.0 / 9.0
        val numerator = (safeRatio * 1000).toInt()
        val params =
            PictureInPictureParams
                .Builder()
                .setAspectRatio(Rational(numerator, 1000))
                .build()
        return current.enterPictureInPictureMode(params)
    }

    fun exit(activity: Activity?) {
        val current = activity ?: return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (current.isInPictureInPictureMode) current.moveTaskToBack(false)
    }
}
