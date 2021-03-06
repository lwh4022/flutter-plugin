import 'dart:convert';
import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chime_plugin/chime_plugin.dart';

import 'MeetingSessionCreator.dart';
import 'data/Attendee.dart';
import 'data/Attendees.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {

  String _version = 'Unknown';
  String _createMeetingSessionResult = 'CreateMeetingSession: Unknown';
  String _audioVideoStartResult = 'AudioVideo: Unknown';
  String _audioVideoStartLocalVideoResult = 'AudioVideoLocalVideo: Unknown';
  String _audioVideoStartRemoteVideoResult = 'AudioVideoRemoteVideo: Unknown';

  final Attendees _attendees = Attendees();
  bool _isAndroidEmulator = false;
  bool _isIosSimulator = false;

  @override
  void initState() {
    super.initState();
    _startChime();
  }

  @override
  Widget build(BuildContext context) {

    var chimeViewChildren = List<Widget>.empty(growable: true);

    if (_attendees.length == 0){
      chimeViewChildren.add(const Expanded(child: Center(child: Text('No attendees yet.'))));
    } else {
      for (int attendeeIndex = 0; attendeeIndex < _attendees.length; attendeeIndex++) {
        Attendee attendee = _attendees[attendeeIndex];
        if (attendee.videoView != null) {
          chimeViewChildren.add(
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: attendee.aspectRatio,
                  child: attendee.videoView
                )
              )
            )
          );
        }
      }
    }

    var chimeViewColumn = Column(children: chimeViewChildren);

    Widget content;

    if (_isAndroidEmulator || _isIosSimulator) {
      content = const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
              child: Text('Chime does not support Android/iOS emulators/simulators.\n\nIf you see the SDK version above then the connection to the SDK works though.')
          )
      );
    } else {
      content = Column(
          children: [
            Text(_createMeetingSessionResult),
            const SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Audio/Video:'),
                  ElevatedButton(
                      child: const Text('Start'),
                      onPressed: ()
                      => _audioVideoStart()
                  ),
                  ElevatedButton(
                      child: const Text('Stop'),
                      onPressed: ()
                      => _audioVideoStop()
                  )
                ]
            ),
            Text(_audioVideoStartResult),
            const SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Local Video:'),
                  ElevatedButton(
                      child: const Text('Start'),
                      onPressed: ()
                      => _audioVideoStartLocalVideo()
                  ),
                  ElevatedButton(
                      child: const Text('Stop'),
                      onPressed: ()
                      => _audioVideoStopLocalVideo()
                  )
                ]
            ),
            Text(_audioVideoStartLocalVideoResult),
            const SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Remote Video:'),
                  ElevatedButton(
                      child: const Text('Start'),
                      onPressed: ()
                      => _audioVideoStartRemoteVideo()
                  ),
                  ElevatedButton(
                      child: const Text('Stop'),
                      onPressed: ()
                      => _audioVideoStopRemoteVideo()
                  )
                ]
            ),
            Text(_audioVideoStartRemoteVideoResult),
            const SizedBox(height: 8),
            Expanded(child: chimeViewColumn)
          ]
      );
    }

    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: const Text('ChimePlugin')),
            body: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(_version),
                  const SizedBox(height: 8),
                  Expanded(child: content)
                ]
            )
        )
    );
  }

  void _startChime() async {

    await _getVersion();

    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.isPhysicalDevice) {
        _addListener();
        await _createMeetingSession();
      }
      else {
        setState(() {
          _isAndroidEmulator = true;
        });
      }
    }
    else if (Platform.isIOS) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      if (iosInfo.isPhysicalDevice) {
        _addListener();
        await _createMeetingSession();
      }
      else {
        setState(() {
          _isIosSimulator = true;
        });
      }
    }
    else {
      _addListener();
      await _createMeetingSession();
    }
  }

  Future<void> _getVersion() async {

    String version;

    try {
      version = (await ChimePlugin.version)!;
    }
    on PlatformException {
      version = 'Failed to get version.';
    }

    if (mounted) {
      setState(() {
        _version = version;
      });
    }
  }

  void _addListener()
  {
    ChimePlugin.eventChannel.receiveBroadcastStream().listen((data) async {
      dynamic event = const JsonDecoder().convert(data);
      String eventName = event['Name'];
      dynamic eventArguments = event['Arguments'];
      switch (eventName) {
        case 'OnVideoTileAdded':
          _handleOnVideoTileAdded(eventArguments);
          break;
        case 'OnVideoTileRemoved':
          _handleOnVideoTileRemoved(eventArguments);
          break;
        default:
          print('Chime.eventChannel.receiveBroadcastStream().listen()/onData()');
          print('Warning: Unhandled event: $eventName');
          print('Data: $data');
          break;
      }
    },
    onDone: () {
      print('Chime.eventChannel.receiveBroadcastStream().listen()/onDone()');
    },
    onError: (e) {
      print('Chime.eventChannel.receiveBroadcastStream().listen()/onError()');
    });
  }

  Future<void> _createMeetingSession() async {
    if (await Permission.microphone.request().isGranted == false) {
      _createMeetingSessionResult = 'Need microphone permission.';
      return;
    }

    if (await Permission.camera.request().isGranted == false) {
      _createMeetingSessionResult = 'Need camera permission.';
      return;
    }

    String meetingSessionState;

    try {
      // Copy the file MeetingSessionCreator.dart.template to MeetingSessionCreator.dart.
      // Adjust MeetingSessionCreator to supply your proper authenticated meeting data.
      // (You can leave the dummy values but you will not be able to join a real meeting.)
      // This requires you to have an AWS account and Chime being set up there.
      // MeetingSessionCreator.dart is to be ignored by git so that your private data never gets committed.

      // See ChimeServer.js on how to create authenticated meeting data using the AWS SDK.

      meetingSessionState = (await MeetingSessionCreator().create())!;
    }
    on PlatformException catch (e) {
      meetingSessionState = 'Failed to create MeetingSession. PlatformException: $e';
    }
    catch (e) {
      meetingSessionState = 'Failed to create MeetingSession. Error: $e';
    }

    if (mounted) {
      setState(() {
        _createMeetingSessionResult = meetingSessionState;
      });
    }
  }

  Future<void> _audioVideoStart() async {
    String result;

    try {
      result = (await ChimePlugin.audioVideoStart())!;
    }
    on PlatformException catch (e) {
      result = 'AudioVideoStart failed: PlatformException: $e';
    }
    catch (e) {
      result = 'AudioVideoStart failed: Error: $e';
    }

    if (mounted) {
      setState(() {
        _audioVideoStartResult = result;
      });
    }
  }

  Future<void> _audioVideoStop() async {
    String result;

    try {
      result = (await ChimePlugin.audioVideoStop())!;
    }
    on PlatformException catch (e) {
      result = 'AudioVideoStop failed: PlatformException: $e';
    }
    catch (e) {
      result = 'AudioVideoStop failed: Error: $e';
    }

    if (mounted) {
      setState(() {
        _audioVideoStartResult = result;
      });
    }
  }

  Future<void> _audioVideoStartLocalVideo() async {
    String result;

    try {
      result = (await ChimePlugin.audioVideoStartLocalVideo())!;
    }
    on PlatformException catch (e) {
      result = 'AudioVideoStartLocalVideo failed: PlatformException: $e';
    }
    catch (e) {
      result = 'AudioVideoStartLocalVideo failed: Error: $e';
    }

    if (mounted) {
      setState(() {
        _audioVideoStartLocalVideoResult = result;
      });
    }
  }

  Future<void> _audioVideoStopLocalVideo() async {
    String result;

    try {
      result = (await ChimePlugin.audioVideoStopLocalVideo())!;
    }
    on PlatformException catch (e) {
      result = 'AudioVideoStopLocalVideo failed: PlatformException: $e';
    }
    catch (e) {
      result = 'AudioVideoStopLocalVideo failed: Error: $e';
    }

    if (mounted) {
      setState(() {
        _audioVideoStartLocalVideoResult = result;
      });
    }
  }

  Future<void> _audioVideoStartRemoteVideo() async {
    String result;

    try {
      result = (await ChimePlugin.audioVideoStartRemoteVideo())!;
    }
    on PlatformException catch (e) {
      result = 'AudioVideoStartRemoteVideo failed: PlatformException: $e';
    }
    catch (e) {
      result = 'AudioVideoStartRemoteVideo failed: Error: $e';
    }

    if (mounted) {
      setState(() {
        _audioVideoStartRemoteVideoResult = result;
      });
    }
  }

  Future<void> _audioVideoStopRemoteVideo() async {
    String result;

    try {
      result = (await ChimePlugin.audioVideoStopRemoteVideo())!;
    }
    on PlatformException catch (e) {
      result = 'AudioVideoStopRemoteVideo failed: PlatformException: $e';
    }
    catch (e) {
      result = 'AudioVideoStopRemoteVideo failed: Error: $e';
    }

    if (mounted) {
      setState(() {
        _audioVideoStartRemoteVideoResult = result;
      });
    }
  }

  void _handleOnVideoTileAdded(dynamic arguments) async {
    bool isLocalTile = arguments['IsLocalTile'];
    int tileId = arguments['TileId'];
    int videoStreamContentHeight = arguments['VideoStreamContentHeight'];
    int videoStreamContentWidth = arguments['VideoStreamContentWidth'];

    Attendee? attendee = _attendees.getByTileId(tileId);
    if (attendee != null) {
      print('_handleOnVideoTileAdded called but already mapped. TileId=${attendee.tileId}, ViewId=${attendee.viewId}, VideoView=${attendee.videoView}');
      return;
    }

    print('_handleOnVideoTileAdded: New attendee: TileId=$tileId => creating ChimeDefaultVideoRenderView');
    attendee = Attendee(tileId, isLocalTile);
    attendee.height = videoStreamContentHeight;
    attendee.width = videoStreamContentWidth;
    _attendees.add(attendee);

    Attendee nonNullAttendee = attendee;
    setState(() {
      nonNullAttendee.setVideoView(
        PAAVideoRenderView(onPlatformViewCreated: (int viewId) async {
          nonNullAttendee.setViewId(viewId);
          print('ChimeDefaultVideoRenderView created. TileId=${nonNullAttendee.tileId}, ViewId=${nonNullAttendee.viewId}, VideoView=${nonNullAttendee.videoView} => binding');
          await ChimePlugin.bindVideoView(nonNullAttendee.viewId!, nonNullAttendee.tileId);
          print('ChimeDefaultVideoRenderView created. TileId=${nonNullAttendee.tileId}, ViewId=${nonNullAttendee.viewId}, VideoView=${nonNullAttendee.videoView} => bound');
        })
      );
    });
  }

  void _handleOnVideoTileRemoved(dynamic arguments) async {
    int tileId = arguments['TileId'];

    Attendee? attendee = _attendees.getByTileId(tileId);
    if (attendee == null) {
      print('Error: _handleOnVideoTileRemoved: Could not find attendee for TileId=$tileId');
      return;
    }

    print('_handleOnVideoTileRemoved: Found attendee: TileId=${attendee.tileId}, ViewId=${attendee.viewId} => unbinding');
    _attendees.remove(attendee);
    await ChimePlugin.unbindVideoView(tileId);
    print('_handleOnVideoTileRemoved: Found attendee: TileId=${attendee.tileId}, ViewId=${attendee.viewId} => unbound');

    setState(() {
      // refresh
    });
  }
}