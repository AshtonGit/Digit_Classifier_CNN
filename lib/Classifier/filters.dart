/*
 * assuming filters are 4D matrices Filter * Y * X * Color channel
 */
import 'dart:math';




List backpropFilter(List<List<List>> image, List<List<List<List>>> filters, List<List<List>> backpropPool, double nLearn, int stride){
  int im_height = image[0].length;
  int im_width = image[0][0].length;  
  int color_channels = image.length;
  int num_filters = filters.length;
  int f_size = filters[0][0].length; //assumed all filters have same dimensions. 
  List<List<List<List>>> filter_gradients = new List<List<List<List<double>>>>(); 
  //initialize filter_gradients to 0
  for(int i =0; i<filters.length; i++){
    filter_gradients.add(new List<List<List<double>>>());
    int color_channels = filters[i].length;
    for(int j =0; j<color_channels; j++){
      filter_gradients[i].add(new List<List<double>>());      
      for(int k = 0; k<f_size; k++){
        filter_gradients[i][j].add(new List<double>());
        for(int h =0; h < f_size; h++) filter_gradients[i][j][k].add(0.0);
      }
    }
  } 
  //calculate gradients to update weights  
  for(int f = 0; f < num_filters; f++){   
    for(int h =0; h + f_size <= im_height; h++){
      for(int w =0; w + f_size <= im_width; w++){
        for( int y = 0; y < f_size; y++){
          for(int x =0; x < f_size; x++){
            for(int c = 0; c < color_channels; c++){
              double delta = backpropPool[f][h][w] * image[c][y + h][x + w];
              filter_gradients[f][c][y][x] += delta;
            }
          }
        }
      }
    }
  }  
   //update weights
  for(int f = 0; f < filters.length; f++){    
    for(int c = 0; c < filters[0].length; c++){      
      for(int y =0; y < f_size; y++){
        for(int x = 0; x < f_size; x++){
          double delta = (filter_gradients[f][c][y][x] * nLearn);
          if(!delta.isNaN){
            filters[f][c][y][x] -=delta;
          }          
        }
      }
    }
  }
  return filters;
}

List<List<List<double>>> convoluteFilter(List<List<List>> image, List<List<List<List>>> filter, int stride ){
  int numFilter = filter.length;
  int numFilterChannel = filter[0].length;
  int filterWindow = filter[0][0].length;  
  int numChannel = image.length;
  int imgHeight = image[0].length;
  int imgWidth = image[0][0].length;
  int newWidth = (((imgWidth - filterWindow) / stride) + 1).round();
  int newHeight = (((imgHeight - filterWindow) / stride) + 1).round();

  assert(numFilterChannel == numChannel);
  List result = buildMatrix(numFilter, newHeight, newWidth);

  for(int i =0; i<numFilter; i++){
    int currY = 0;    
    while(currY + filterWindow <= imgHeight){
      int currX = 0;     
      while(currX + filterWindow <= imgWidth){        
        List<List<List>> slice = new List<List<List<double>>>();
        for(int j =0; j<numChannel; j++){
          List<List> selectRows =List.from(image[j].getRange(currY, currY+filterWindow));
          List channelSlice = new List<List<double>>();
          selectRows.forEach((r)=> channelSlice.add(r.getRange(currX, currX+filterWindow).toList()) );   
          slice.add(channelSlice);          
        }
        List filtered = applyFilter(slice, filter[i]);
        //sum all values of window 
        result[i][currY][currX] = filtered.fold(0.0, (a,b)=> a + b.fold(0.0, (x,y)=> x+y));
        currX++;
      }
      currY++;
    }
  }
  return result;
}

List buildMatrix(int x, int y, int z){
  List matrix = new List<List<List<double>>>();
  for(int i=0; i<x; i++){
    List edge = new List<List<double>>();
    for(int j =0; j < y; j++){
      List<double> row = new List<double>();
      for(int c = 0; c < z; c++){
        row.add(0);
      }
      edge.add(row);
    }
    matrix.add(edge);
  }
  return matrix;
}

List applyFilter(List<List<List<double>>> image, List<List<List<double>>> filter){
  int channels = image.length;
  int height = image[0].length;
  int width = image[0][0].length;
  
  List<List<double>> result = new List<List<double>>();
  assert(channels == filter.length); //throw an exception if fail
  for(int i = 0; i<height; i++){
    List<double> row = new List<double>();
    for(int j = 0; j<width; j++){   
      double sum = 0;     
      for(int z =0; z < channels; z++){
        sum += image[z][i][j] * filter[z][i][j];
      }
      row.add(sum);
    }
    result.add(row);
  }
  return result;
}

List createRandomFilter(int width, int height, int channels, double min, double max){
  List<List<List<double>>> filter = new List<List<List<double>>>();
  for(int c = 0; c < channels; c++){
    Random random = new Random(DateTime.now().millisecond);
    List<List> rows = new List<List<double>>();
    for(int y = 0; y <height; y++){
      List<double> weights = new List<double>();
      for(int x = 0; x < width; x++){
        weights.add((min + random.nextDouble() * (max-min)) / 9); 
      }
      rows.add(weights);
    }
    filter.add(rows);
  }
  return filter;
}


double activationLeakyRelu(double output){
  if(output <= 0) return output * 0.01;
  else{
    return output;
  }
}

/*
 * This relies on leakyReluActivation having a multiplier
 * of 0.01 for x <= 0. If the multiplier changes, this function
 * must change to match
 */
List batchDerivativeLeakyRelu(List<double> outputs){
  List derivatives = new List<double>();
  outputs.forEach((x){
    if(x > 0) derivatives.add(1);
    else{
      derivatives.add(0.01);
    }
  });
  return derivatives;
}

double derivativeLeakyRelu(double output){
  if(output > 0) return 1;
  else{
    return 0.01;
  }
}



