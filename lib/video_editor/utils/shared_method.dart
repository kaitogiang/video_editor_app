import 'dart:convert';
import 'dart:developer';

// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:video_editor_app/video_editor/widgets/loading_screen.dart';

//Method for showing the loading screen and prevent the user interaction
Future<dynamic> showLoadingStatus(BuildContext context) async {
  return showDialog(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (context) => const LoadingScreen(),
  );
}

Future<List<String>> extractVideoFrame(String videoPath) async {
  log('Video path is: $videoPath');
  const String basePath = '/storage/emulated/0/Download/';
  String video = videoPath;
  List<String> imagePath = [];
  String commandToExecute =
      '-i $video -r 1 -f image2 ${basePath + 'image-%4d.png'}';
  await FFmpegKit.execute(commandToExecute).then((session) async {
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      log('Extract image from video successfully');
    } else if (ReturnCode.isCancel(returnCode)) {
      log('Cancel extract image from video');
    } else {
      log('Error extract image from video');
    }
  });
  for (int i = 1; i <= 10; i++) {
    imagePath.add('$basePath image-${i.toString().padLeft(4, '0')}.png');
  }
  return imagePath;
}

Stream<String> extractVideoFrameStream(String videoPath) async* {
  log('Video path is: $videoPath');
  const String basePath = '/storage/emulated/0/Download/';
  String video = videoPath;
  List<String> imagePath = [];
  String commandToExecute =
      '-i $video -r 1 -f image2 ${basePath + 'image-%4d.png'}';
  await FFmpegKit.execute(commandToExecute).then((session) async {
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      log('Extract image from video successfully');
    } else if (ReturnCode.isCancel(returnCode)) {
      log('Cancel extract image from video');
    } else {
      log('Error extract image from video');
    }
  });
  final videoDurationInSecond = await getVideoInformation(videoPath);
  log('Video duration in extractVideoFrameStream: ${videoDurationInSecond}');
  for (int i = 1; i <= 17; i++) {
    // imagePath.add('$basePath image-000$i.png');
    String imagePath = '${basePath}image-${i.toString().padLeft(4, '0')}.png';
    yield imagePath;
  }
}

Future<int> getVideoInformation(String videoPath) async {
  return await FFprobeKit.getMediaInformation(videoPath).then((session) async {
    final information = session.getMediaInformation();

    if (information != null) {
      log(information.getAllProperties()!['streams'].toString());
      final streams =
          information.getAllProperties()!['streams'] as List<dynamic>;
      final durationMap = streams[0];
      // final duration = durationMap['duration'];
      log(durationMap['duration']);
      final duration = durationMap;

      //Check the Following attributes on error,
      //Get other attribute
      // final state =
      //     FFmpegKitConfig.sessionStateToString(await session.getState());
      // final returnCode = await session.getReturnCode();
      // final failStackTrace = await session.getFailStackTrace();
      // final output = await session.getOutput();
      //Get the duration of the video, the duration has a second unit
      //It will convert the video duration to second
      // final outputMapString = await session.getOutput();
      // final outputMap = jsonDecode(outputMapString!) as Map<String, dynamic>;
      // final duration = outputMap['format']['duration'];
      // log('State: $state');
      // log('FailStackTrace: $failStackTrace');
      // log('Output: $output');
      log('Log 1 - getVideoDuration - information != null: Duration: ${duration}');
      return duration;
    } else {
      log('Log 2 - getVideoDuration - information == null: Duration');
      return 0;
    }
  }).onError((error, e) {
    log('Error in getVideoInformation: $error');
    return 0;
  });
}
