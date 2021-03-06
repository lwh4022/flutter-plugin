package com.paathena.chime_plugin.observers

import com.amazonaws.services.chime.sdk.meetings.device.DeviceChangeObserver
import com.amazonaws.services.chime.sdk.meetings.device.MediaDevice
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

class PAADeviceChangeObserver (private val _eventSink: EventChannel.EventSink) : DeviceChangeObserver {

    override fun onAudioDeviceChanged(mediaDevices: List<MediaDevice>) {
        val jsonObject = JSONObject()
        val eventArguments = JSONObject()
        eventArguments.put("MediaDevices", convertMediaDevicesToJson(mediaDevices))
        jsonObject.put("Name", "OnAudioDeviceChanged")
        jsonObject.put("Arguments", eventArguments)
        _eventSink.success(jsonObject.toString())
    }

    private fun convertMediaDevicesToJson(mediaDevices: List<MediaDevice>): JSONArray {
        val list = JSONArray()

        for (mediaDevice in mediaDevices) {
            val item = JSONObject()
            item.put("Label", mediaDevice.label)
            item.put("Order", mediaDevice.order)
            item.put("Type", mediaDevice.type)
            list.put(item)
        }

        return list
    }
}