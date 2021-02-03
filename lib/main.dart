import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  configLoading();
  runApp(MyApp());
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 5000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = Colors.black
    ..indicatorColor = Colors.white
    ..textColor = Colors.white
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Editor',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
      builder: EasyLoading.init(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isVideoSelected;
  String _videoPath;
  String _textContent;
  String _buttonText1;
  String _buttonText2;
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  String _outAudioPath;
  String _outVideoPath;
  Dio _dio;
  final String _url = "https://ve.mycodeacademia.com/audio/";

  @override
  void initState() {
    super.initState();
    _isVideoSelected = false;
    _videoPath = "";
    _textContent = "Please select a video to process.";
    _buttonText1 = "Select Video";
    _buttonText2 = "Process Video";
    _dio = Dio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Editor"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _getText(),
            SizedBox(height: 16.0),
            _getSelectionButton(),
            SizedBox(height: 16.0),
            if(_isVideoSelected) _getProcessButton(),
          ],
        ),
      ),
    );
  }

  Widget _getSelectionButton() {
    return RaisedButton(
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 28.0),
      color: Colors.deepPurple,
      child: Text(
        _buttonText1,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.0,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      onPressed: () async {
        print("Select button pressed");
        FilePickerResult result = await FilePicker.platform.pickFiles(type: FileType.video);
        if(result != null) {
          _videoPath = result.files.single.path;
          setState(() {
            _isVideoSelected = true;
            _textContent = "Video Path: $_videoPath";
          });
        } else {
          print("You cancelled!");
        }
      },
    );
  }

  Widget _getProcessButton() {
    return RaisedButton(
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
      color: Colors.deepPurple,
      child: Text(
        _buttonText2,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.0,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      onPressed: () async {
        print("Process button pressed");
        _getPaths();
      },
    );
  }

  Text _getText() {
    return Text(
      _textContent,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.deepPurple,
        fontSize: 16.0,
      ),
    );
  }

  void _getPaths() async {
    EasyLoading.show(status: "Processing file...", dismissOnTap: false);
    
    Directory baseDir;

    if (Platform.isAndroid) {
      baseDir = await getExternalStorageDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final myPath = '${baseDir.path}/EditedVideos' ;
    final myDir = await new Directory(myPath).create();

    _outAudioPath = myDir.path + '/' + DateTime.now().toString().replaceAll(" ", "_").replaceAll(".", "") + '.wav';
    _outVideoPath = myDir.path + '/' + DateTime.now().toString().replaceAll(" ", "_").replaceAll(".", "") + '.mp4';

    print(_outAudioPath);
    print(_outVideoPath);
    
    _flutterFFmpeg.execute("-i $_videoPath $_outAudioPath").then((value) async {
      if (value == 0) {
        _processFurther();
      } else {
        await EasyLoading.dismiss();
        EasyLoading.showError("FFMPEG audio conversion failed. Try again.", duration: Duration(seconds: 3), dismissOnTap: true);
      }
    });
  }

  void _processFurther() async {
    FormData formData = FormData.fromMap({
      "audio_file": await MultipartFile.fromFile(_outAudioPath, filename: "upload.wav")
    });
    try {
      Response response = await _dio.post(_url, data: formData);

      print(response.headers);
      print(response.data);
      print(response.statusCode);
      print(response.statusMessage);

      if (response.data['error']) {
        await EasyLoading.dismiss();
        EasyLoading.showError(response.data['details'], duration: Duration(seconds: 3), dismissOnTap: true);
      } else {
        String v = response.data['details'];
        _flutterFFmpeg.execute('-i $_videoPath -filter_complex "' + v + '" -map "[out]" "$_outVideoPath"').then((value) async {
          if (value == 0) {
            File f = File(_outAudioPath);
            await f.delete();
            await EasyLoading.dismiss();
            EasyLoading.showSuccess("Success!", duration: Duration(seconds: 3), dismissOnTap: true);
            setState(() {
              _textContent = "Video file saved at: $_outVideoPath";
            });
          } else {
            await EasyLoading.dismiss();
            EasyLoading.showError("FFMPEG video conversion failed. Try again.", duration: Duration(seconds: 3), dismissOnTap: true);
          }
        });
      }
    } on SocketException {
      await EasyLoading.dismiss();
      EasyLoading.showError("Error! Check your internet connection and try again.", duration: Duration(seconds: 4), dismissOnTap: true);
    }
    catch (e) {
      print(e.toString());
      await EasyLoading.dismiss();
      EasyLoading.showError("Error! Something went wrong. Please try again.", duration: Duration(seconds: 4), dismissOnTap: true);
    }
  }
}
