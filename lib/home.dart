// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:fruit_getx/main.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var result = '';
  bool isWorking = false;
  CameraController? cameraController;
  CameraImage? imgCamera;

  initCamera() {
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController!.startImageStream((imageFromStream) => {
              if (!isWorking)
                {
                  isWorking = true,
                  imgCamera = imageFromStream,
                  runModelOnStreamFrames(),
                }
            });
      });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/detect.tflite',
      labels: 'assets/labelmap.text',
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    loadModel();
  }

  @override
  void dispose() async {
    // TODO: implement dispose
    super.dispose();

    await Tflite.close();
    cameraController?.dispose();
  }

  runModelOnStreamFrames() async {
    var recognitions = await Tflite.runModelOnFrame(
      bytesList: imgCamera!.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageWidth: imgCamera!.width,
      imageHeight: imgCamera!.height,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 2,
      threshold: 0.1,
      asynch: true,
    );
    result;

    recognitions!.forEach((response) {
      result += response['label'] +
          '' +
          (response['confidence'] as double).toStringAsFixed(2) +
          '\n\n';
    });
    setState(() {
      result;
    });
    isWorking = false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Objetos Detector App Getx'),
          backgroundColor: Colors.deepOrange,
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(color: Colors.orange),
          child: Column(children: [
            Stack(
              children: [
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 100.0),
                    height: 220,
                    width: 320,
                    color: Colors.deepOrangeAccent,
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      initCamera();
                    },
                    child: Container(
                        margin: const EdgeInsets.only(top: 65.0),
                        height: 270,
                        width: 360,
                        child: imgCamera == null
                            ? Container(
                                height: 270,
                                width: 360,
                                child: Icon(
                                  Icons.photo_camera_front,
                                  color: Colors.black,
                                  size: 60.0,
                                ),
                              )
                            : AspectRatio(
                                aspectRatio:
                                    cameraController!.value.aspectRatio,
                                child: CameraPreview(cameraController!),
                              )),
                  ),
                )
              ],
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 55.0),
                child: SingleChildScrollView(
                  child: Text(
                    result,
                    style: const TextStyle(
                      backgroundColor: Colors.black87,
                      fontSize: 25.0,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
