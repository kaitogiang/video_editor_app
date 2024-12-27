import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_editor_app/video_editor/utils/shared_method.dart';

class VideoFrame extends StatefulWidget {
  const VideoFrame({super.key, required this.file});

  final File file;

  @override
  State<VideoFrame> createState() => _VideoFrameState();
}

class _VideoFrameState extends State<VideoFrame> {
  final List<String> _framesPath = [];
  bool isTap = false;
  @override
  void initState() {
    super.initState();
    _startExtractingFrames(widget.file.path);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startExtractingFrames(String videoPath) async {
    log('Starting extract frames');
    // String videoPath = widget.videos[0].path;
    await for (String imagePath in extractVideoFrameStream(videoPath)) {
      setState(() {
        _framesPath.add(imagePath);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isTap = !isTap;
        });
      },
      child: Container(
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
          itemCount: _framesPath.length,
          itemBuilder: (context, index) {
            return Container(
              width: 100,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Image.file(
                File(_framesPath[index]),
                fit: BoxFit.fitWidth,
              ),
            );
          },
        ),
      ),
    );
  }
}
