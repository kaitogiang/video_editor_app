import 'dart:convert';
import 'dart:developer';
import 'dart:io';

// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_editor_app/video_editor/widgets/add_text_form.dart';
import 'package:video_editor_app/video_editor/widgets/bottom_modal.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:video_editor_app/video_editor/widgets/loading_screen.dart';
import 'package:video_editor_app/video_editor/widgets/select_options.dart';

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
  //Get the lastModified date to distinguish between the files
  File videoFile = File(videoPath);
  final lastMotifiedDate = await videoFile.lastModified();
  String lastModifiedDateString =
      lastMotifiedDate.toIso8601String().replaceAll(':', '');
  // String video = videoPath;
  String commandToExecute =
      '-i $videoPath -r 1 -f image2 ${basePath + '$lastModifiedDateString-image-%4d.png'}';
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
  for (int i = 1; i <= videoDurationInSecond; i++) {
    // imagePath.add('$basePath image-000$i.png');
    String imagePath =
        '${basePath}${lastModifiedDateString}-image-${i.toString().padLeft(4, '0')}.png';
    yield imagePath;
  }
}

Future<int> getVideoInformation(String videoPath) async {
  File videoFile = File(videoPath);
  final lastMotifiedDate = videoFile.lastModified();
  return await FFprobeKit.getMediaInformation(videoPath).then((session) async {
    final information = session.getMediaInformation();

    if (information != null) {
      //Check the Following attributes on error,
      //Get other attribute
      final state =
          FFmpegKitConfig.sessionStateToString(await session.getState());
      final returnCode = await session.getReturnCode();
      final failStackTrace = await session.getFailStackTrace();
      final output = await session.getOutput();
      // Get the duration of the video, the duration has a second unit
      // It will convert the video duration to second
      final outputMapString = await session.getOutput();
      final outputMap = jsonDecode(outputMapString!) as Map<String, dynamic>;
      final duration = outputMap['format']['duration'];
      // log('State: $state');
      // log('FailStackTrace: $failStackTrace');
      // log('Output: $output');
      log('Log 1 - getVideoDuration - information != null: Duration: ${duration}');
      //Decode map string into Map
      // return duration['duration'] as int;
      double doubleDuration = double.parse(duration.toString());
      return doubleDuration.toInt();
    } else {
      log('Log 2 - getVideoDuration - information == null: Duration');
      return 0;
    }
  }).onError((error, e) {
    log('Error in getVideoInformation: $error');
    return 0;
  });
}

//The method for options
Future<dynamic> buildAddTextDialog(BuildContext context) {
  return showBottomDialog(
    context: context,
    heightFactor: 0.85,
    widthFactor: 1,
    child: const AddTextForm(),
  );
}

Future<dynamic> buildOptionDialog(BuildContext context) async {
  return showBottomDialog(
    context: context,
    heightFactor: 0.71,
    child: SelectOptions(
      options: {
        'Take photo': () async {
          final file = await _takePhotoAction();
          log('Selected file in buildOptionDialog: ${file?.path}');
          Navigator.of(context, rootNavigator: true).pop(file);
        },
        'Choose image from gallery': _selectImageFromGallery,
        'DreamWeaiver Gallery': () {
          log('DreamWeaiver Gallery');
        },
        'Choose video from gallery': () async {
          final videoFile = await _selectVideoFromGallery();
          // final videoPlayerController = VideoPlayerController.file(videoFile!)
          //   ..initialize();
          // log('Video player controller in _buildOptionDialog: ${videoPlayerController.value.duration}');
          Navigator.of(context, rootNavigator: true).pop(videoFile);
        },
        'Record video': _recordVideo,
        'AI Images': () {
          log('AI Images');
        }
      },
    ),
  );
}

//Methods for handling the selected option
Future<File?> _takePhotoAction() async {
  log('Take photo from the camera directly');
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.camera);
  if (image != null) {
    //Do something here
    log('Image path: ${image.path}');
    return File(image.path);
  }
  return null;
}

Future<void> _selectImageFromGallery() async {
  log('Select image from gallery');
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    //Do something here
    log('Image path in the gallery: ${image.path}');
    final imageFile = File(image.path);
  }
}

Future<File?> _selectVideoFromGallery() async {
  final picker = ImagePicker();
  final video = await picker.pickVideo(source: ImageSource.gallery);
  if (video != null) {
    //Do something here
    log('Video path in the gallery is: ${video.path}');
    return File(video.path);
  }
  return null;
}

Future<void> _recordVideo() async {
  final picker = ImagePicker();
  final video = await picker.pickVideo(source: ImageSource.camera);
  if (video != null) {
    //Do something here
    log('Recoreded video path : ${video.path}');
  }
}
