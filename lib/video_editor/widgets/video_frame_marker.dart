import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class VideoFrameMarker extends StatefulWidget {
  const VideoFrameMarker({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  State<VideoFrameMarker> createState() => _VideoFrameMarkerState();
}

class _VideoFrameMarkerState extends State<VideoFrameMarker> {
  double maxScroll = 0.0;

  @override
  void initState() {
    super.initState();
     maxScroll = widget.scrollController.position.maxScrollExtent;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [],
    );
  }
}
