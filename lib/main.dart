import 'dart:async';
import 'dart:io';
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
    _requestStoragePermission();
    _initAudioRecorder();
  }

 Future<void> _initAudioRecorder() async {
    await _audioRecorder!.openRecorder();
  }

  Future<void> _startRecording() async {
    PermissionStatus status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime++;
      });
    });

    Directory appDir = await getApplicationDocumentsDirectory();
    String basePath = appDir.path;
    _filePath = '$basePath/audio_recording.mp4';
     await _audioRecorder.startRecorder(
      toFile: _filePath,
      codec: Codec.aacMP4,
    );
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _elapsedTime = 0;

    await _audioRecorder.stopRecorder();
  }

  Future<void> _playAudio() async {
    try {
      await _audioPlayer.openPlayer();
      await _audioPlayer.startPlayer(fromURI: _filePath, codec: Codec.aacMP4);
    } catch (e) {
      print('Erro ao reproduzir áudio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.resumePlayer();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
    } else if (status.isDenied) {
    } else if (status.isPermanentlyDenied) {
    }
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
              onPressed: _playAudio,
              child: Text('Play Recording'),
            ),
            SizedBox(height: 16),
            Text('Elapsed Time: $_elapsedTime seconds'),
          ],
        ),
      ),
    );
  }
}
