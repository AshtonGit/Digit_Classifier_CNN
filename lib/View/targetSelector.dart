import 'package:cnndigitrecog/Classifier/classifier.dart';
import 'package:flutter/material.dart';


class TargetSelector extends StatefulWidget{
  Classifier classifier;
  Output output;
  TargetSelector(this.classifier, this.output);
 @override
  _TargetSelectorState createState(){
    return _TargetSelectorState(this.classifier, this.output);
  }


}

class _TargetSelectorState extends State<TargetSelector>{

  _TargetSelectorState(this.classifier, this.output);
  int selected = 0;
  int min = 0;
  int max = 9;
  Classifier classifier;
  Output output;

  void incrementSelection(int modifier){
    int newSelection = selected + modifier;
    if(newSelection >= min && newSelection <= max)setState(() {
     selected = newSelection; 
    });  
  }

  @override
  Widget build(BuildContext context){
    return AlertDialog(
       title: new Text("What number did you draw?"),
       content: new Text(selected.toString()),       
       actions : <Widget>[
        new IconButton(
          icon: Icon(Icons.keyboard_arrow_up),
          color: Colors.lightBlueAccent,
          highlightColor: Colors.white,
          onPressed:() => incrementSelection(1),
        ),
        new IconButton(
          icon: Icon(Icons.keyboard_arrow_down),
          color: Colors.lightBlueAccent,
          highlightColor: Colors.white,
          onPressed: () {incrementSelection(-1);}
        ),  
        new FlatButton(
          child: new Text("TRAIN"),
          onPressed: (){
              classifier.userDirectedTraining(output, selected);
        //      classifier.saveToFile("assets/training_classifier.json");
              Navigator.of(context).pop();
          } 
        )      
      ]
    );
  } 


}

