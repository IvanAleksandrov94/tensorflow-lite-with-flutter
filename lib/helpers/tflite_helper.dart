import 'dart:async';

import 'package:camera/camera.dart';
import 'package:machine_learning_flutter_app/models/result.dart';
import 'package:tflite/tflite.dart';

class TFLiteHelper {
  static StreamController<List<Result>> tfLiteResultsController = new StreamController.broadcast();
  static List<Result> _outputs = List();
  static var modelLoaded = false;

  static Future<String> loadModel() async {
    return Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  static classifyImage(CameraImage image) async {
    await Tflite.runModelOnFrame(
            bytesList: image.planes.map((plane) {
              return plane.bytes;
            }).toList(),
            imageHeight: image.height,
            imageWidth: image.width,
            imageMean: 127.5, // defaults to 127.5
            imageStd: 127.5, // defaults to 127.5
            rotation: 90, // defaults to 90, Android only
            numResults: 2, // defaults to 5
            threshold: 0.1, // defaults to 0.1
            asynch: true)
        .then((value) {
      if (value.isNotEmpty) {
        _outputs.clear();

        value.forEach((element) {
          _outputs.add(Result(element['confidence'], element['index'], element['label']));
        });
      }

      _outputs.sort((a, b) => a.confidence.compareTo(b.confidence));

      tfLiteResultsController.add(_outputs);
    });
  }

  static void disposeModel() {
    Tflite.close();
    tfLiteResultsController.close();
  }
}
