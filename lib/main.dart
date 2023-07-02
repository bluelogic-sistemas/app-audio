import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MaterialApp(
    title: 'Audio Recorder Demo',
    home: AudioRecorderScreen(),
  ));
}

class AudioRecorderScreen extends StatefulWidget {
  @override
  _AudioRecorderScreenState createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  String _filePath = '';
  int _elapsedTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _configAudioRecorder();
  }

  Future _requestPermission() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.microphone, Permission.audio].request();
  }

  Future<void> _configAudioRecorder() async {
    await _audioRecorder.openRecorder();
  }

  Future<void> _startRecording() async {
    await _requestPermission();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime++;
      });
    });

    _filePath = await audioFileName();
    await _audioRecorder.startRecorder(
      toFile: _filePath,
      codec: Codec.aacMP4,
    );
  }

  Future<String> audioFileName() async {
    DateTime now = DateTime.now();
    Directory appDir = await getApplicationDocumentsDirectory();
    String basePath = appDir.path;
    return "${basePath}/AUD${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}${now.millisecond}.mp4";
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _elapsedTime = 0;

    await _audioRecorder.stopRecorder();
  }

  Future<void> _playAudioLocal() async {
    try {
      final player = AudioPlayer(playerId: "teste1");
      await player.setVolume(1);
      await player.setSourceDeviceFile(_filePath);
      await player.play(DeviceFileSource(_filePath));
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  Future<void> _playAudioServer() async {
    try {
      final player = AudioPlayer(playerId: "teste1");
      await player.play(UrlSource(
          'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3'));
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.resumePlayer();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startRecording,
              child: Text('Start Recording'),
            ),
            ElevatedButton(
              onPressed: _stopRecording,
              child: Text('Stop Recording'),
            ),
            ElevatedButton(
              onPressed: _playAudioLocal,
              child: Text('Play Recording'),
            ),
            ElevatedButton(
              onPressed: _playAudioServer,
              child: Text('Play Recording server'),
            ),
            SizedBox(height: 16),
            Text('Elapsed Time: $_elapsedTime seconds'),
          ],
        ),
      ),
    );
  }
}
