/*
 * reverses pooling process, returning a matrices the size of the original 
 * kernels. Indices of the matrices that held the max value which was used as the input
 * are given the gradient for that input. Other indices are given 0 value. 
 *  * assume all kernels are the same size. 
 * assume all the pool windows are the same size
 * inputGradients are gradients for the input layer neurons of the softmax classifier calculated during backprop. 
 * pools are output of maxPooling during forward propagation.
 * kernels are the result of applying a filter to the source image. Each kernel is one filter applied to the whole image
 * kernelCount = how many kernels there were in prev layer
 * prevHeight, prevWidth = the dimensions of the kernels in prev layer. Assumed all kernels were same size
 */


poolBackprop(List<double> pools, List<double> inputGradients, List<List<List<double>>> kernels, int poolSize){
  
//initialize output matrix. create 3d array, kernel * height * width
  List<List<List<double>>> results = new List<List<List<double>>>();
  int numKernel = kernels.length;
  int kernelHeight = kernels[0].length; 
  for(int i = 0; i < numKernel; i++){
    results.add(new List<List<double>>());
    for(int j =0; j < kernelHeight; j++) results[i].add(new List<double>());
  }

  int height = kernels[0].length;
  int width = kernels[0][0].length;  
  int pool = 0;
  bool maxFound = false;

  for(int k =0; k < kernels.length; k++){
    for(int y =0; y + poolSize <= height; y = y + poolSize){
      for(int x = 0; x + poolSize <= width; x = x + poolSize){
        for(int i = y; i < y + poolSize; i++){// (changed to) <= y + poolsize from < y + poolsize
          for(int j = x; j < x + poolSize; j++){         
            if(!maxFound && kernels[k][i][j] == pools[pool]){ //updated from kernels[k][y][x]
              maxFound = true;
              results[k][i].add(inputGradients[pool]);
            }else{
              results[k][i].add(0.0);
            }
          }
        }
        pool++;
        maxFound = false;
      }
    }
  }
  return results;
}




/*
 * returns a flattened list of inputs for the softmax classifier.
 * The values ar gained by iterating a "window" over the kernels. 
 * Within each window the max value is taken and added to the list.
 */
List maxPool(List<List<List<double>>> kernels, int poolWindow){
  List<double> pool = new List<double>();
  kernels.forEach((k){
    int height = k.length;
    int width = k[0].length;    
    for(int i =0; i<height; i = i + poolWindow){ //iterate through all indexes of kernel
        for(int j =0; j<width; j = j+ poolWindow){
          double localMax = k[i][j];
          for(int y = i; y < i+poolWindow; y++){
            for(int x = j+1; x < j+poolWindow; x++){
              if(y < height && x < width){ //prevent array out of bounds
                if(k[y][x] > localMax) localMax = k[y][x];
              }
            }
          }
          pool.add(localMax);
        }
    }
  });
  return pool;
}

List buildMatrix(int x, int y, int z){
  List matrix = new List<List<List<int>>>(x);
  for(int i=0; i<x; i++){
    List edge = new List<List<int>>(y);
    for(int j =0; j < y; j++){
      edge.add(new List<int>(z));
    }
    matrix.add(edge);
  }
  return matrix;
}




List downsample(List<List<List<int>>> image, int frameSize, int strideSize){
  int channels = image.length;
  int prevHeight = image[0].length;
  int prevWidth = image[0][0].length;
  int newHeight = (((prevHeight - frameSize)/ strideSize) + 1).round(); 
  int newWidth =  (((prevWidth - frameSize) / strideSize) + 1).round();
  List downSample = buildMatrix(channels, newHeight, newWidth);
  for(int i=0; i<channels; i++){
    int currentY = 0; 
    int outY = 0;
    while(currentY + frameSize <= prevHeight){
      int currentX = 0;
      int outX = 0;
      while(currentX + frameSize <= prevWidth){
        downSample[i][outY][outX] 
        = maxFromWindow(image[i],currentY, currentY+frameSize, currentX, currentX+frameSize);
        currentX += strideSize;
        outX += 1;
      }
      currentY += strideSize;
      outY += 1;
    }
  }
  return downSample;

}

/*
 * traverse down y first to be consistent with downsample method. 
 * Downsample method scans image left to right and then moving down vertically
 * each pass. Therefore the first index is the y axis.  
 */
int maxFromWindow(List<List<int>> matrix, int startY, int endY, int startX, int endX){
  int max = matrix[startY][startX];
  for(int i = startY; i < endY; i++){
    for(int j = startX+1; j<endX; j++){
        int a = matrix[i][j];
        if( a > max) max = a;
    }
  }
  return max;
} 
