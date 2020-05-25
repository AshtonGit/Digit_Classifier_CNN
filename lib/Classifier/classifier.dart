
import 'package:image/image.dart';
import 'dart:convert';
import "dart:io";
import 'dart:math';
import 'filters.dart';
import 'imageparser.dart';
import 'neuralnetwork.dart';
import 'pooling.dart';


class Classifier{

  NeuralNetwork _network;
  List<List<List<List<double>>>> _filters;  
  int pool_size;
  double learn_rate;
  int stride = 1;  
 /*
 * int channels: number color channels in images network is designed to classify.
 * num_pools: number of pooling layers
 * pool_size: width of the pool windows. pool windows dimensions are pool_size x pool_size.
 */
  Classifier(List<int> layout, List<double> params, double min_w, double max_w, int num_filter, int filter_size, int channels){
      this._network = new NeuralNetwork.randomInitialized(layout, params[0], min_w, max_w);   
      this.learn_rate = params[0];       
      this.pool_size = params[1].round();
      _filters = new List<List<List<List<double>>>>();
      Random rand = new Random(DateTime.now().millisecond);
      for(int i =0; i< num_filter; i++){
        _filters.add(createRandomFilter(filter_size, filter_size, channels, min_w, max_w));  
      }
  }



  List<double> classify(List<List<List<double>>> input){    
    List<List<List>> kernels = convoluteFilter(input, _filters,  stride);
    List pool = maxPool(kernels, pool_size);
    List<List<double>> output =  _network.classify(pool);
    return output[output.length-1];
  }

  Output classifyUserGeneratedInput(Image image){
    List input = imageToInstanceData(image, 28);
    List<List<List>> kernels = convoluteFilter(input, _filters,  stride);
    List pool = maxPool(kernels, pool_size);
    List<List<double>> neuralOut =  _network.classify(pool);
    Output output = new Output(kernels, pool, neuralOut, input);
    return output;
  }

  
  Classifier.fromJson(String json){
    Map<String, List> data = _decodeJson(json);
    _network = new NeuralNetwork(data["weights"], data["params"]); 
    _filters = data["filters"];  
    learn_rate = data["params"][0];
    double ps = data["params"][1];
    pool_size = ps.round();
  }

  Classifier.fromFile(String dir){
    Map<String, List> data = _decodeJsonFile(dir);
    _network = new NeuralNetwork(data["weights"], data["params"]); 
    _filters = data["filters"];  
    learn_rate = data["params"][0];
    double ps = data["params"][1];
    pool_size = ps.round();
  }

  train(List<List<List<double>>> input, List<double> target){     
    List<List<List>> kernels = convoluteFilter(input, _filters,  stride);   
    List pool = maxPool(kernels, pool_size);
    List<double> input_gradients = _network.trainWithInput(pool, target);
    List backprop_pool = poolBackprop(pool, input_gradients, kernels, pool_size);
    _filters = backpropFilter(input, _filters, backprop_pool, learn_rate, stride);    
  }

  /*
   * When program incorrectly classifies a user generated input, the user can request
   * that program trains itself on the users input. Users provide the target and as the instance
   * has already been classified the training algorithm can start at backpropogation. 
   */
  userDirectedTraining(Output output, int target){
    int numClasses = output.getNumClasses();
    List tar = new List<double>(numClasses);
    //build the target list
    for(int i =0; i < numClasses; i++){
      if(i == target) tar[i] = 1.0;
      else{ tar[i] = 0.0;}
    }
    List<double> input_gradients = _network.trainWithOutput(output.neuralOut, tar);
    List backprop_pool = poolBackprop(output.pools, input_gradients, output.kernels, pool_size);
    _filters = backpropFilter(output.input, _filters, backprop_pool, learn_rate, stride);  


  }

bool isClassificationCorrect(List<double> output, List<double> target){
  if(output.length != target.length){
    throw FormatException("output and target mismatch, ");
  } 
  int len = output.length;
  double tmax = target[0];
  double omax = output[0];
  int tmax_i = 0;
  int omax_i = 0;
  for(int i =1; i<len; i++){
    if(output[i] > omax){
      omax = output[i];
      omax_i = i;
    }
    if(target[i] > tmax){
      tmax = target[i];
      tmax_i = i;
    }
  }
  return(tmax_i == omax_i);
}

  void saveToFile(String dir){  
    Map fields = new Map<String, List>();      
    fields["params"] = _network.getParams();
    fields["params"].add(pool_size.toDouble());   
    fields["weights"] = _network.getNetwork();
    fields["filters"] = _filters;    
    File file = new File(dir);
    file.writeAsStringSync(json.encode(fields));    
  }
  
  
  Map<String, List> _decodeJsonFile(String dir){
    File json = new File(dir);
    String content = json.readAsStringSync();
    return _decodeJson(content);
  }

  Map<String, List> _decodeJson(String content){    
    Map<String, List<dynamic>> data = Map.from(json.decode(content));  
     Map<String, List> fields = new Map<String, List>();
     List weights = new List<List<List<double>>>();
     List filters = new List<List<List<List<double>>>>();
     
     List params = new List<double>();
     data["weights"].forEach((la){
       List layer = new List<List<double>>();
      la.forEach((lb){
        List node = new List<double>();
        lb.forEach((x)=> node.add(double.parse(x.toString())) );
        layer.add(node);
      });
      weights.add(layer);
     });

    data["filters"].forEach((filter){
      List f = new List<List<List<double>>>();
      filter.forEach((channel){
        List c = new List<List<double>>();
        channel.forEach((y){
          List col = new List<double>();
          y.forEach((x)=> col.add(double.parse(x.toString())));
          c.add(col);
        });
        f.add(c);
      });
      filters.add(f);
    });
    fields["filters"] = filters;      
    data["params"].forEach((p)=> params.add(double.parse(p.toString())));
    fields["weights"] = weights;       
    fields["params"] = params;
    return fields;
    
  } 
  
}


class Output{
  List<List<List>> kernels;
  List pools;
  List<List<double>> neuralOut;
  List<List<List<double>>> input;
  Output(this.kernels, this.pools, this.neuralOut, this.input);

  int getNumClasses(){
    int len = neuralOut.length;
    return neuralOut[len-1].length;
  }


  List<double> getResult(){
       return this.neuralOut[neuralOut.length - 1];
  }

  int getClassificationIndx(){
    List result = this.getResult();
    int len = result.length;   
    double max = -1;
    int maxIndx = -1;
    for(int i = 0; i < len; i++){
      if(result[i] > max){
        max = result[i];
        maxIndx = i;
      }
    }
    return maxIndx;
  }
}