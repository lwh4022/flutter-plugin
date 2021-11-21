package com.paathena.chime_plugin.views

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class PAAVideoRenderViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE){

    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val view = PAAVideoRenderView(context)
        viewIdToViewMap[viewId] = view
        return view
    }

    companion object {
        private val viewIdToViewMap: MutableMap<Int, PAAVideoRenderView> = HashMap()

        fun getViewById(id: Int): PAAVideoRenderView? = viewIdToViewMap[id]

        fun clearViewIds() {
            viewIdToViewMap.clear()
        }
    }
}