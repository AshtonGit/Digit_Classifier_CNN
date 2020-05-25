import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'View/sketchpage.dart';

Future<void> main() async{
  

  runApp(MaterialApp(
    title: "Digit Demo",
    theme: ThemeData.dark(),
    home: Draw(),
  ));
}


class MyHomePage extends StatefulWidget {
  final CameraDescription camera;

  MyHomePage({
    Key key,
    @required this.camera,
    }) : super(key: key);
  

  

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
 

  @override
  void initState(){
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar( title: Text('Draw a number between 1 & 9')),
      
      
    );
  }
}


