import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:machine_learning_flutter_app/helpers/camera_helper.dart';
import 'package:machine_learning_flutter_app/helpers/tflite_helper.dart';
import 'package:machine_learning_flutter_app/models/result.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DetectScreen extends StatefulWidget {
  DetectScreen({Key key,}) : super(key: key);

  

  @override
  _DetectScreenPageState createState() => _DetectScreenPageState();
}

class _DetectScreenPageState extends State<DetectScreen> with TickerProviderStateMixin {
  AnimationController _colorAnimController;
  Animation _colorTween;

  List<Result> outputs;

  void initState() {
    super.initState();

    TFLiteHelper.loadModel().then((value) {
      setState(() {
        TFLiteHelper.modelLoaded = true;
      });
    });

    CameraHelper.initializeCamera();

    _setupAnimation();

    TFLiteHelper.tfLiteResultsController.stream.listen(
        (value) {
          value.forEach((element) {
            _colorAnimController.animateTo(element.confidence,
                curve: Curves.bounceIn, duration: Duration(milliseconds: 500));
          });

          outputs = value;

          setState(() {
            CameraHelper.isDetecting = false;
          });
        },
        onDone: () {},
        onError: (error) {
        });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<void>(
          future: CameraHelper.initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                children: <Widget>[
                  CameraPreview(CameraHelper.camera),
                  _buildResultsWidget(width, outputs)
                ],
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    TFLiteHelper.disposeModel();
    CameraHelper.camera.dispose();
    super.dispose();
  }

  Widget _buildResultsWidget(double width, List<Result> outputs) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 200.0,
          width: width,
          color: Colors.white,
          child: outputs != null && outputs.isNotEmpty
              ? ListView.builder(
                  itemCount: outputs.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20.0),
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: <Widget>[
                        Text(
                          outputs[index].label,
                          style: TextStyle(
                            color: _colorTween.value,
                            fontSize: 20.0,
                          ),
                        ),
                        AnimatedBuilder(
                            animation: _colorAnimController,
                            builder: (context, child) => LinearPercentIndicator(
                                  width: width * 0.88,
                                  lineHeight: 14.0,
                                  percent: outputs[index].confidence,
                                  progressColor: _colorTween.value,
                                )),
                        Text(
                          "${(outputs[index].confidence * 100.0).toStringAsFixed(2)} %",
                          style: TextStyle(
                            color: _colorTween.value,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    );
                  })
              : Center(
                  child: Text("Ожидание модели",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                      ))),
        ),
      ),
    );
  }

  void _setupAnimation() {
    _colorAnimController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _colorTween = ColorTween(begin: Colors.green, end: Colors.red).animate(_colorAnimController);
  }
}
