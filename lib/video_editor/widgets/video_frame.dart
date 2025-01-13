import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_editor_app/video_editor/models/frame.dart';
import 'package:video_editor_app/video_editor/utils/shared_method.dart';

class VideoFrame extends StatefulWidget {
  const VideoFrame({super.key, required this.file});

  final File file;

  @override
  State<VideoFrame> createState() => _VideoFrameState();
}

class _VideoFrameState extends State<VideoFrame> {
  final StreamController<Frame> _streamController = StreamController<Frame>();
  final List<Frame> _videoFrames = [];
  bool isTap = false;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    // _startExtractingFrames(widget.file.path);
    _startExtractingFrames(widget.file.path);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // void _startExtractingFrames(String videoPath) async {
  //   log('Starting extract frames');
  //   await for (String imagePath in extractVideoFrameStream(videoPath)) {
  //     _framesPath.add(imagePath);
  //   }
  //   setState(() {
  //     isLoading = false;
  //   });
  // }
  void _startExtractingFrames(String videoPath) async {
    extractVideoFrameStream(videoPath).listen((receivedFrame) {
      //Add the new frame to the controller and the list of frames
      _videoFrames.add(receivedFrame);
      _streamController.add(receivedFrame);
    }, onDone: () {
      log('Extracting all the frames is done');
    }, onError: (error) {
      log('There is an error while extracting frames: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isTap = !isTap;
        });
      },
      child: StreamBuilder(
          stream: _streamController.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(
                color: Colors.white,
              );
            }
            return Container(
              //Getting the full width of the whole video duration
              //1000 milisecond = 60 offset
              width: _videoFrames.fold(0,
                  (previous, currentFrame) => previous! + currentFrame.width),
              decoration: BoxDecoration(
                border: isTap
                    ? const Border.fromBorderSide(
                        BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      )
                    : null,
              ),
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _videoFrames.length,
                addRepaintBoundaries:
                    false, //Prevent adding the RepaintBoundary to the child
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 60,
                    height: 50,
                    // margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Image.file(
                      File(_videoFrames[index].imagePath),
                      fit: BoxFit.fill,
                    ),
                  );
                },
              ),
            );
          }),
    );
  }
}
