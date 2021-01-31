import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
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

  @override
  void initState() {
    super.initState();
    _isVideoSelected = false;
    _videoPath = "";
    _textContent = "Please select a video to process.";
    _buttonText1 = "Select Video";
    _buttonText2 = "Process Video";
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
}
