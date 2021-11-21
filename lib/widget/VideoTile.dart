import 'dart:io';

import 'package:flutter/material.dart';

/// A view where local or remote video gets rendered
class PAAVideoRenderView extends StatefulWidget
{
  /// Event to be called when the view gets created
  final ValueChanged<int>? onPlatformViewCreated;

  /// Creates a [ChimeDefaultVideoRenderView].
  /// Optional: [onPlatformViewCreated] event to be called when the view gets created.
  PAAVideoRenderView({this.onPlatformViewCreated});

  @override
  _PAAVideoRenderViewState createState()
  => _PAAVideoRenderViewState();
}

class _PAAVideoRenderViewState extends State<PAAVideoRenderView>
{
  @override
  Widget build(BuildContext context)
  {
    if (Platform.isAndroid)
    {
      return AndroidView(
        viewType: 'ChimeDefaultVideoRenderView',
        onPlatformViewCreated: (int viewId)
        => widget.onPlatformViewCreated?.call(viewId),
      );
    }
    else if (Platform.isIOS)
    {
      return UiKitView(
        viewType: 'ChimeDefaultVideoRenderView',
        onPlatformViewCreated: (int viewId)
        => widget.onPlatformViewCreated?.call(viewId),
      );
    }
    else
      throw Exception('Not implemented');
  }
}