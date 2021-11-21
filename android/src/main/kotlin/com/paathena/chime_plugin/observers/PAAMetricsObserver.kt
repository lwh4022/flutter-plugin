package com.paathena.chime_plugin.observers

import com.amazonaws.services.chime.sdk.meetings.audiovideo.metric.MetricsObserver
import com.amazonaws.services.chime.sdk.meetings.audiovideo.metric.ObservableMetric
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject

class PAAMetricsObserver (private val _eventSink: EventChannel.EventSink) : MetricsObserver {

    override fun onMetricsReceived(metrics: Map<ObservableMetric, Any>) {
        val jsonObject = JSONObject()
        val eventArguments = JSONObject()
        eventArguments.put("Metrics", convertMetricsToJson(metrics))
        jsonObject.put("Name", "OnMetricsReceived")
        jsonObject.put("Arguments", eventArguments)
        _eventSink.success(jsonObject.toString())
    }

    private fun convertMetricsToJson(metrics: Map<ObservableMetric, Any>): JSONObject {
        val jsonObject = JSONObject()

        for (metric in metrics)
            jsonObject.put(metric.key.toString(), metric.value.toString())

        return jsonObject
    }
}