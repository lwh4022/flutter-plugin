package com.paathena.chime_plugin.views

import android.content.Context
import android.view.View
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.DefaultVideoRenderView
import com.amazonaws.services.chime.sdk.meetings.audiovideo.video.VideoRenderView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class PAAVideoRenderView internal constructor(context: Context?) : PlatformView, MethodChannel.MethodCallHandler {

    private val _defaultVideoRenderView: DefaultVideoRenderView = DefaultVideoRenderView(context!!)

    val videoRenderView: VideoRenderView get() = _defaultVideoRenderView

    override fun dispose() = Unit

    override fun getView(): View = _defaultVideoRenderView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) = result.notImplemented()
}