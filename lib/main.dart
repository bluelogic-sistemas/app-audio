import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

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
  String _filePathMp3 = '';
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
    await _audioRecorder.openAudioSession();
  }

  Future<void> _startRecording() async {
    await _requestPermission();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime++;
      });
    });

    _filePath = await audioFileName("aac");
    _filePathMp3 = await audioFileName("mp3");
    await _audioRecorder.startRecorder(
        toFile: _filePath, audioSource: AudioSource.microphone);
  }

  Future<String> audioFileName(typeFile) async {
    DateTime now = DateTime.now();
    Directory appDir = await getApplicationDocumentsDirectory();
    String basePath = appDir.path;
    return "${basePath}/AUD${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}${now.millisecond}.$typeFile";
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
      await FlutterSoundHelper()
          .convertFile(_filePath, Codec.aacADTS, _filePathMp3, Codec.mp3);

      //_filePath = await convertToOgg(_filePath, _filePath.replaceAll(".mp4", ".mp3"));
      await player.setSourceDeviceFile(_filePathMp3);
      await player.play(DeviceFileSource(_filePathMp3));
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  Future<void> _playAudioServer() async {
    try {
      final player = AudioPlayer(playerId: "teste1");
      _filePath = await audioFileName("ogg");
      _filePathMp3 = await audioFileName("mp4");
      await downloadAndSaveFile("https://s3.amazonaws.com/dadosusuarios/100000/producao/mubichat/2023/07/04072023090133_3A71A20BE47A3CA417A4.ogg", _filePath);
      // final fileBytes = await downloadFileAsBytes(
      //     'https://s3.amazonaws.com/dadosusuarios/100000/producao/mubichat/2023/07/04072023090133_3A71A20BE47A3CA417A4.ogg');

      await FlutterSoundHelper()
          .convertFile(_filePath, Codec.opusOGG, _filePathMp3, Codec.aacMP4);

      await player.setSourceDeviceFile(_filePathMp3);
      await player.play(DeviceFileSource(_filePathMp3));
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  Future<void> downloadAndSaveFile(String url, String filePath) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  Future<Uint8List> downloadFileAsBytes(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return Uint8List.fromList(response.bodyBytes);
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
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
