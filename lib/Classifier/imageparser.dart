import 'dart:io';
import 'package:image/image.dart';
/**
 * Takes camera images and transforms the pixel data into arrays of doubles.
 * These arrays are used as input data for the Neural Network
 */




  /*
    Extracts instance data. Image is greyscale so the pixel data is stored as a 2D array,
    one index per pixel. Only need one data point for greyscale as RGB are identical.
  */

List<List<List>> imageToInstanceData(Image image, int width){
  List pixels =  image.getBytes();
  List result = new List<List<double>>();
  List<double> row = new List<double>();
  int i = 0;
  int x = 0;
  
  pixels.forEach((b){    
    if(i  == 0){      
      if(x == width ){
        x = 0;
        result.add(row);
        row = new List<double>();
      }
      x++;
      row.add(255 - b.toDouble()); //have to invert value as MNIST database uses white numbers on a black background.
      
    } else if(i == 3) i = -1;   
    i++;
  });
  result.add(row); 
  List out = new List<List<List<double>>>();
  out.add(result);
  return out;
}
 