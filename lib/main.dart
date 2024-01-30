import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as dev;
import 'package:text_to_speech/text_to_speech.dart';

class Prediction {
  final String nominal;
  final double max_val;
  final bool isMoney;

  const Prediction(
      {required this.nominal, required this.max_val, required this.isMoney});

  factory Prediction.fromJson(Map<String, dynamic> json) {
    debugPrint('data: ${json}');
    return (json != null)
        ? Prediction(
            nominal: json['nominal'] as String,
            max_val: (json['max_val'] as num).toDouble(),
            isMoney: json['money'] as bool,
          )
        : throw const FormatException('Failed to load prediction.');
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Money Detection'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //final FlutterTts flutterTts = FlutterTts();
  File? selectedImage;
  String? message = "";
  TextToSpeech tts = TextToSpeech();
  Future<Prediction>? _futurePrediction;

  Future<Prediction> uploadImage() async {
    final request = http.MultipartRequest(
        "POST", Uri.parse("https://jhon404.pythonanywhere.com/api/upload"));
    final headers = {"Content-Type": "multipart/form-data"};

    request.files.add(http.MultipartFile('image',
        selectedImage!.readAsBytes().asStream(), selectedImage!.lengthSync(),
        filename: selectedImage!.path.split("/").last));

    request.headers.addAll(headers);
    final response = await request.send();
    http.Response res = await http.Response.fromStream(response);
    final resJson = jsonDecode(res.body);
    //Map<String, dynamic>? data = new Map<String, dynamic>.from(resJson);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Prediction.fromJson(resJson as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create prediction');
    }
  }

  Future getImage() async {
    final pickedImage =
        await ImagePicker().getImage(source: ImageSource.gallery);
    selectedImage = File(pickedImage!.path);
    setState(() {
      _futurePrediction = null;
    });
  }

  Future getImagefromCamera() async {
    var image = await ImagePicker().pickImage(source: ImageSource.camera);
    selectedImage = File(image!.path);

    setState(() {
      _futurePrediction = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: buildColumn()),
      floatingActionButton: TextButton.icon(
          style: ButtonStyle(
              fixedSize: MaterialStateProperty.all(Size(150, 80)),
              backgroundColor: MaterialStateProperty.all(Colors.black)),
          onPressed: () {
            getImagefromCamera();
          },
          icon: Icon(
            Icons.add_a_photo,
            color: Colors.white,
          ),
          label: Text(
            "Ambil Gambar",
            style: TextStyle(color: Colors.white),
          )),
    );
  }

  Column buildColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 200,
          height: 400,
          child: Column(
            children: <Widget>[
              Container(
                child: (_futurePrediction == null)
                    ? Column(
                        children: <Widget>[
                          selectedImage == null
                              ? Text(
                                  "Gambar",
                                )
                              : Image.file(selectedImage!),
                        ],
                      )
                    : buildFutureBuilder(),
              )
            ],
          ),
        ),
        TextButton.icon(
            style: ButtonStyle(
                fixedSize: MaterialStateProperty.all(Size(250, 80)),
                backgroundColor: MaterialStateProperty.all(Colors.red)),
            onPressed: () {
              setState(() {
                _futurePrediction = uploadImage();
              });
            },
            icon: Icon(
              Icons.upload_file,
              color: Colors.white,
            ),
            label: Text(
              "Deteksi Gambar",
              style: TextStyle(color: Colors.white),
            ))
      ],
    );
  }

  FutureBuilder<Prediction> buildFutureBuilder() {
    return FutureBuilder<Prediction>(
      future: _futurePrediction,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          //_speak(snapshot.data!.nominal);
          String nominal = snapshot.data!.nominal;
          tts.setLanguage('id-ID');
          tts.speak('uang anda ${nominal}');
          if (nominal == '') {
            tts.speak('Bukan uang');
          }
          return nominal == '' ? Text('Bukan uang') : Text('${nominal}');
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        tts.speak('Tunggu sebentar hingga gambar dideteksi');
        return const CircularProgressIndicator();
      },
    );
  }
}
