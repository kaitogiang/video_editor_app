import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class VideoFrameMarker extends StatefulWidget {
  const VideoFrameMarker({super.key});

  @override
  State<VideoFrameMarker> createState() => _VideoFrameMarkerState();
}

class _VideoFrameMarkerState extends State<VideoFrameMarker> {
  double maxScroll = 0.0;
  int maximumDurationInSecond = 120;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const emptySpace = SizedBox(
      height: 50,
      width: 180,
    );
    final timeLineMarker =
        List<Widget>.generate(maximumDurationInSecond, (index) {
      final duration = Duration(seconds: index);
      return SizedBox(
        width: 60,
        child: Text(
          formatter(duration),
          style: theme.textTheme.bodySmall!.copyWith(
            color: Colors.white,
          ),
        ),
      );
    });
    return Row(
      children: [
        emptySpace,
        ...timeLineMarker,
      ],
    );
  }
}
