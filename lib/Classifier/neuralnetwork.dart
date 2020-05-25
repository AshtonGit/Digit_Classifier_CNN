
import 'dart:math';
import 'dart:math' as math;


class NeuralNetwork{
  double max;
  double min;
  double nLearn;
  double dmax;
  double momentum;
  double flatElim;
  List<List<List<double>>> _network;
  
/*
 * to do
 * 
 * 
 * - connect all stages of the neural network and test them on the handwritten digit dataset. 
 * - use the digit dataset as a unit test alongside other unit tests to ensure safety and correctness.
 * - there are lots of downcasts between InputNode and activated nodes, 
 * ensure these casts work before looking for any other causes of bugs.
 * 
 */

  NeuralNetwork(this._network, List params){
    nLearn = params[0];
  }

  NeuralNetwork.randomInitialized(List<int> layout, this.nLearn, this.min, double this.max){
    List<List<List<double>>> network = new List<List<List<double>>>();
    int len = layout.length;
    for(int i =1; i<len; i++){ //skip the input layer as it has no weights. Weights are stored from child to parent.
      List<List<double>> layer = new List<List<double>>();
      int input_len = layout[i-1];
      for(int j = 0; j < layout[i]; j++){ 
        List<double> weights = new List<double>();
        Random random = new Random(DateTime.now().millisecond);
        for(int n = 0; n<=layout[i-1]; n++){ //final weight is the bias
          weights.add((min + (max-min) * random.nextDouble()) / input_len); //divide by number of inputs to produce small inital weights
        }
        layer.add(weights);
      }
      network.add(layer);
    }
    _network = network;
  }

  

 

  double evaluateNode(List<double> weights, List<double> inputs){
    if(weights.length != inputs.length + 1){
      throw new FormatException("Number of Weights("+weights.length.toString()+") and Inputs("+inputs.length.toString()+") do not match");
    }
    double sum = 0.0;
    int len = inputs.length;
    for(int i = 0; i<len; i++){
      sum+= inputs[i] * weights[i];
    }    
    sum += weights[len];// add the bias
    return sum;
  }
  
  /*
 * Returns result as an array of doubles. 
 * Results are activated via tha SoftMax method which creates a probability range
 * where sum of all probabilities equals 1. 
 * For the purposes of training, the output of the nodes in final layer are the activated results too.
 */
  List<List<double>> classify(List<double> instance){
    int num_layers = _network.length;
    List<List<double>> output = new List<List<double>>();
    int output_indx = _network.length;
    output.add(instance);
    for(int i = 0; i < num_layers; i++){
      List<double> layer_out = new List<double>();
      int num_nodes = _network[i].length;
      for(int j = 0; j < num_nodes; j++){
        if(i == output_indx - 1){
          layer_out.add(evaluateNode(_network[i][j], output[i]));
        }
        else{
          layer_out.add(activationLeakyRelu(evaluateNode(_network[i][j], output[i])));
        }
      }
      output.add(layer_out);
    }    
    List<double> softmax = activationSoftMax(output[output_indx]);
    output[output_indx] = softmax;
    return output;

  }

 
  List<List<double>> backPropagate(List<List<double>> output, List<double> target){
    List<List<double>> errorSignal = new List<List<double>>(output.length);
    int output_indx = output.length - 1;
        
    for(int i = output_indx; i >= 0; i--){ 
      errorSignal[i] = new List<double>();
       if( i == output_indx){
         for(int j = 0; j<target.length; j++)errorSignal[i].add(output[i][j] - target[j]);
       }       
       else{
          int len = output[i].length;
          for(int n = 0; n < len; n++){
            double error = 0.0;
            int children = output[i+1].length;
            for(int c = 0; c < children; c++){
              double weight = _network[i][c][n]; //weight from child to current node
              error += weight * errorSignal[i+1][c];
            }
            if(i != 0) error = error * derivativeLeakyRelu(output[i][n]);           
            errorSignal[i].add(error);
          }
       }
    }  
    return errorSignal;
  }
  

  List<double> trainWithInput(List<double> input, List<double> target){
  List<List<double>> output = classify(input); //return matrix with all the outputs for each node
  List<List<double>> errorSignal = backPropagate(output, target);
  for(int i = 0; i<_network.length; i++){
    int layer_len = _network[i].length;
    for(int j =0; j < layer_len; j++){
      List<double> weights = _network[i][j];
      int weights_len = weights.length - 1;
      for(int w =0; w < weights_len; w++){
        double delta = nLearn * errorSignal[i+1][j] * output[i][w]; //errorSignal of currentNode * output of parent node weight connects to
        if(!delta.isNaN){
          weights[w] -= delta;
        }
      }
      double delta = nLearn * errorSignal[i+1][j];
      if(!delta.isNaN){
        weights[weights_len] -= delta; //update bias
      }
      
    }
  }  
  return errorSignal[0];
}


List<double> trainWithOutput(List<List<double>> output, List<double> target){
  List<List<double>> errorSignal = backPropagate(output, target);
  for(int i = 0; i<_network.length; i++){
    int layer_len = _network[i].length;
    for(int j =0; j < layer_len; j++){
      List<double> weights = _network[i][j];
      int weights_len = weights.length - 1;
      for(int w =0; w < weights_len; w++){
        double delta = nLearn * errorSignal[i+1][j] * output[i][w]; //errorSignal of currentNode * output of parent node weight connects to
        if(!delta.isNaN){
          weights[w] -= delta;
        }
      }
      double delta = nLearn * errorSignal[i+1][j];
      if(!delta.isNaN){
        weights[weights_len] -= delta; //update bias
      }
      
    }
  }  
  return errorSignal[0];
}






List batchActivationRelu(List<double> outputs){
  List activated = new List<double>();
  outputs.forEach((x){
    activated.add(math.max(0, x));
  });
  return activated;
}

/* Leaky ReLU has a small slope for negative values insteal of altogether 0.
 * Leaky Relu has two benefits compared to standard relu
 * 1. Fixes the "dying relu" problem as there are no zero slope parts
 * 2. speeds up training as having the mean activation be close to 0 makes training
 *   faster.
 * Be aware results are not always consistent and Leaky ReLU wont always be superior 
 * to plain ReLU
 */
List batchActivationLeakyRelu(List<double> outputs){
  List activated = new List<double>();
  outputs.forEach((x){
    if(x <= 0) activated.add( x * 0.01);
    else{
      activated.add(x);
    }
  });
  return activated;
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

double activationSigmoid(double output){
  return 1 / (1 +  pow(e, -output) );
}

List<double> activationSoftMax(List<double> output){
  double sum = 0.0;
  int len = output.length;
  double e = math.e;
  output.forEach((o)=> sum+= pow(e, o));
  for(int i = 0; i<len; i++){
    output[i] = pow(e, output[i]) / sum;
  }
  return output;
}


double crossEntropyCost(List<double> target, List<double> results){
  double error = 0.0;
  int len = target.length;
  for(int i =0; i<len; i++){
    error -= (results[i] * math.log(target[i]));
  }
  return error;
}

double transferDerivSigmoid(double output){
  return output*(1 - output);
}

double meanSquaredError(double target, double output){
  return pow(target - output, 2) / 2;
}



/*
 * A copy of the network is returned to avoid side effects
 */
List getNetwork(){
  return List.from(_network);
}


List getParams(){
  List<double> params = new List<double>();
  params.add(nLearn);
  return params;
}
 



}