import 'dart:io';
import 'dart:ui';
import 'package:cnndigitrecog/Classifier/classifier.dart';
import 'package:flutter/material.dart';

import 'drawingpoint.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;


enum SelectedMode { StrokeWidth, Opacity, Color }

class DrawingPoints {
  Paint paint;
  Offset points;
  DrawingPoints({this.points, this.paint});
}

class Draw extends StatefulWidget {
  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<Draw> {
  Color selectedColor = Colors.black;
  Color pickerColor = Colors.black;
  double strokeWidth = 20.0;
  List<DrawingPoints> points = List();
  double opacity = 1.0;
  StrokeCap strokeCap = (Platform.isAndroid) ? StrokeCap.round : StrokeCap.round;
  SelectedMode selectedMode = SelectedMode.StrokeWidth;
  List<Color> colors = [Colors.black ];
  bool showLoading = false;
  double canvasOffsetY = 50;
  Classifier classifier;
  DrawingPainter painter;
  int result = -1;


  @override
  void initState(){
    super.initState();
    setState(() {
      painter = DrawingPainter(pointsList: points);  
    });    
  }

  
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.0), 
                color: Colors.greenAccent),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton( 
                        icon: Icon(Icons.save),
                        onPressed: (){
                          classifier.saveToFile("assets/training_classifier.json");
                        },
                      ),
                      Expanded(
                        child:  FlatButton(                            
                          child: Text("CLASSIFY"),
                          onPressed: () {
                            setState(() => showLoading = true );
                            classify();                          
                          }),                         
                        flex: 3,
                      ),                                         
                      IconButton(
                          icon: Icon(Icons.clear),                          
                          onPressed: () {
                            setState(() {
                              points.clear();
                            });
                          }),
                    ],
                  ),
                ],
              ),
            )),
      ),
      body: Padding(
          padding: EdgeInsets.only(top: canvasOffsetY),
          child: Container(
              decoration: new BoxDecoration(
              color: Colors.white,
              ),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {                                   
                    points.add(DrawingPoints(
                        points: details.globalPosition.translate(0, -canvasOffsetY),// compensates for canvas offset
                        paint: Paint()
                          ..strokeCap = strokeCap
                          ..isAntiAlias = true
                          ..color = selectedColor.withOpacity(opacity)
                          ..strokeWidth = strokeWidth));
                    painter = DrawingPainter(pointsList: points);
                  });
                },
                onPanStart: (details) {
                  setState(() {  
                    points.add(DrawingPoints(
                        points: details.globalPosition.translate(0, -canvasOffsetY),
                        paint: Paint()
                          ..strokeCap = strokeCap
                          ..isAntiAlias = true
                          ..color = selectedColor.withOpacity(opacity)
                          ..strokeWidth = strokeWidth));
                    painter = DrawingPainter(pointsList: points);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    points.add(null);
                  });
                },                
                child:  CustomPaint(
                  size: Size.square(MediaQuery.of(context).size.width),
                  painter: painter,              
                ),
            
              ),
            ),
          ),
    );
  }

  
  Widget colorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 16.0),
          height: 36,
          width: 36,
          color: color,
        ),
      ),
    );
  }

  classify() async{   
    if(this.classifier == null){
      Classifier loadClassifier =  new Classifier.fromJson(await rootBundle.loadString('assets/training_classifier.json'));
      painter.classify(loadClassifier).then((output){      
        setState(() {
        result = output.getClassificationIndx();
        showLoading = false;
        classifier = loadClassifier;
        displayResultDialog(output);
        });
      });
    }else{
      painter.classify(classifier).then((output){      
      setState(() {
       result = output.getClassificationIndx();
       showLoading = false;
       classifier = classifier;
       displayResultDialog(output);
      });
    });
    }
    
  }

  void displayResultAlert(Output output){
      showDialog(context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: new Text("I think the number is.."),
            content: new Text(result.toString(), textAlign: TextAlign.center,),           
            actions: <Widget>[ 
              new FlatButton(
                child: Text("OK"),  
                color: Colors.grey,              
                onPressed: (){
                  setState(()=> points.clear());
                  Navigator.of(context).pop();                  
                },
              ),
            ],
          );
        }
      );
  }

  void displayResultDialog(Output output){
      showDialog(context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: new Text("I think the number is.."),
            content: new Text(result.toString()+"\n\ndid i get it right?", textAlign: TextAlign.center,),           
            actions: <Widget>[ 
              new FlatButton(
                child: Text("Yes"),  
                color: Colors.grey,              
                onPressed: (){
                  setState(()=> points.clear());
                  Navigator.of(context).pop();                  
                },
              ),
              new FlatButton(
                child: Text("No"),
                color: Colors.blueGrey,
                onPressed: (){
                  Navigator.of(context).pop();
                  displayTrainDecisionDialog(output);                  
                } 
              ),
            ],
          );
        }
      );
  }

  void displayTrainDecisionDialog(Output output){
    showDialog(context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: new Text("Oops") ,
          content: new Text("Use this sketch to train the classifier?"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("YES"),
              onPressed: (){                
                Navigator.of(context).pop();
              }
            ),
            new FlatButton(
              child: new Text("NO"),
              onPressed: (){ 
                setState(()=> points.clear());
                Navigator.of(context).pop();                
              }
            ),
          ],
        );
      }
    
    );
  }


  void trainClassifier(Output output, int target){
    classifier.userDirectedTraining(output, target);
  }


}




class DrawingPainter extends CustomPainter {
  DrawingPainter({this.pointsList});
  List<DrawingPoints> pointsList;
  List<Offset> offsetPoints = List(); 
  Size _lastSize;
  @override
  void paint(Canvas canvas, Size size) {       
    _lastSize = size;
    canvas.drawColor(Colors.white, BlendMode.color);
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        //if two consecutive points are available, draw a line
        canvas.drawLine(pointsList[i].points, pointsList[i + 1].points,
            pointsList[i].paint);
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        offsetPoints.clear();
        offsetPoints.add(pointsList[i].points);
        offsetPoints.add(Offset(
            pointsList[i].points.dx + 0.1, pointsList[i].points.dy + 0.1));
        //if two points are not next to each other, draw two individual points
        canvas.drawPoints(PointMode.points, offsetPoints, pointsList[i].paint);
      }
    }
  }


/*
 * Resizes image drawn by user into a 28 x 28 format. 
 */
  Future<img.Image> getTransformedImageData()async{
  //  if(_lastCanvas == null || _lastSize == null) return null;
    var recorder = new PictureRecorder();
    var origin = new Offset(0.0,0.0);
    var paintBounds = new Rect.fromPoints(_lastSize.topLeft(origin), _lastSize.bottomRight(origin));
    var canvas = new Canvas(recorder, paintBounds);
    paint(canvas, _lastSize);
    var picture = recorder.endRecording();
    var image = await picture.toImage(_lastSize.width.round(), _lastSize.height.round());
    var byteData = await image.toByteData();
    img.Image imgz = new img.Image.fromBytes(_lastSize.width.round(), _lastSize.height.round(), byteData.buffer.asUint32List()); //recast image as img.Image to allow resizing from image library
   return img.grayscale(img.copyResize(imgz, width: 28, height: 28));  
  }
   

   /*
   * Classifies the digit drawn by user. 
   * image obtained by recording the canvas.
   * int is the digit identified eg 0,1,2...9
   * -1 is caused if no x in result is equal to 1, and returns a formaterror flag
   */
  Future<Output> classify (Classifier classifier) async{
    var image = await getTransformedImageData();
    Output output = classifier.classifyUserGeneratedInput(image);
    return output;
  }

 @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;//oldDelegate.pointsList!=pointsList;

}