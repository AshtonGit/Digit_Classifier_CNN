
/*
 * This class extracts instance data for the classifier from data files. 
 */
import 'dart:io';
import 'dart:convert';

class FileParser{



  static  List<List<double>> readUnsupervisedData(String directory){
    File file = new File(directory);
    List<List<double>> instances = new List<List<double>>();
    if(file.existsSync()){      
      var stream = file.openRead();
      stream.transform(Utf8Decoder()).transform(LineSplitter())
      .listen((String line){
        List row = line.split(',');
        List<double> instance = new List<double>();
        row.forEach((n){           
          instance.add(double.parse(n));
        });
        instances.add(instance);
      });
    }else{
      throw new Exception("File at"+directory+" doesnt exist");
    }
    return instances;
  }

  static Map<List<List<double>>, List<double>> readSupervisedDigitData(String dir, int num_classes){
    File digits = new File(dir);
    Map<List<List<double>>, List<double>> instances = new Map<List<List<double>>, List<double>>();
   
    if(digits.existsSync()){            
      digits.readAsLinesSync().forEach((String line){ 
        line = line.substring(0, line.length-1);      
        List<List<double>> instance = new List<List<double>>();
        List<double> row = new List<double>();
        List<double> label = new List<double>(num_classes);  
        bool labelled = false;      
        double i = 0;
        line.split(",").forEach((n){                 
          if(!labelled){
            label = buildLabel(int.parse(n), num_classes);
            labelled = true;
          }else{               
            row.add(double.parse(n));     
            i++;       
            if(i%28==0){
              instance.add(row);
              row = new List<double>();
            }                     
          }          
        });        
        instances[instance] = label;        
        labelled = false;
      });        
    }else{
      throw new Exception("File at"+dir+" doesnt exist");
    }
    return instances;
  }

  static List<double> buildLabel(int classification, int num_classes){
    assert(classification <= num_classes);
    List<double> label = new List<double>(num_classes);
    for(int i=0; i<num_classes; i++){
      if(i == classification)label[i] = 1;
      else{
        label[i] = 0;
      }
    }
    return label;
  }
} 

