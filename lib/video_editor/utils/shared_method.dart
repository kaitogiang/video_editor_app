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
import 'package:path_provider/path_provider.dart';
import 'package:video_editor_app/video_editor/models/frame.dart';
import 'package:video_editor_app/video_editor/models/media.dart';
import 'package:video_editor_app/video_editor/widgets/add_text_form.dart';
import 'package:video_editor_app/video_editor/widgets/bottom_modal.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:video_editor_app/video_editor/widgets/loading_screen.dart';
import 'package:video_editor_app/video_editor/widgets/select_options.dart';

enum MediaType {
  video,
  image,
}

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

Stream<Frame> extractVideoFrameStream(String videoPath) async* {
  log('Video path is: $videoPath');
  // const String basePath = '/storage/emulated/0/Download/';
  final tempDir = await getTemporaryDirectory();
  //Get the lastModified date to distinguish between the files
  File videoFile = File(videoPath);
  final lastMotifiedDate = await videoFile.lastModified();
  String lastModifiedDateString =
      lastMotifiedDate.toIso8601String().replaceAll(':', '');
  // String video = videoPath;
  String commandToExecute =
      '-i $videoPath -r 1 -f image2 ${tempDir.path + '/' + '$lastModifiedDateString-image-%4d.png'}';
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
  //The duration in second (double type)
  final videoDurationInSecond = await getVideoInformation(videoPath);
  //Convert to milisecond
  final durationInMilisecond = (videoDurationInSecond * 1000).toInt();
  //Getting the number of images, if the duration has remainder, add 1
  final numberOfImages = durationInMilisecond % 1000 > 0
      ? durationInMilisecond ~/ 1000 + 1
      : durationInMilisecond ~/ 1000;
  //Extracted the remaining frame of the video
  if (durationInMilisecond % 1000 > 0) {
    final imagePath =
        '${tempDir.path + '/' + '$lastModifiedDateString-image-${numberOfImages.toString().padLeft(4, '0')}.png'}';
    String remainingFrameCommand =
        '-i $videoPath -ss $videoDurationInSecond -vframes 1 $imagePath';
  }
  log('Video duration in extractVideoFrameStream: ${videoDurationInSecond}');
  for (int i = 1; i <= numberOfImages; i++) {
    final Frame? videoFrame;
    String imagePath =
        '${tempDir.path}/$lastModifiedDateString-image-${i.toString().padLeft(4, '0')}.png';
    if (i != numberOfImages) {
      videoFrame = Frame(imagePath: imagePath, durationInMilisecond: 1000);
    } else {
      //If there is a remainder, change the milisecond to the remaining milisecond
      if (durationInMilisecond % 1000 > 0) {
        videoFrame = Frame(
            imagePath: imagePath,
            durationInMilisecond: durationInMilisecond % 1000);
      } else {
        videoFrame = Frame(imagePath: imagePath, durationInMilisecond: 1000);
      }
    }
    yield videoFrame;
  }
}

Future<double> getVideoInformation(String videoPath) async {
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

      return doubleDuration;
    } else {
      log('Log 2 - getVideoDuration - information == null: Duration');
      return 0.0;
    }
  }).onError((error, e) {
    log('Error in getVideoInformation: $error');
    return 0.0;
  });
}

Future<int> getVideoDurationInMilisecond(String videoPath) async {
  return await FFprobeKit.getMediaInformation(videoPath).then((session) async {
    final information = session.getMediaInformation();

    if (information != null) {
      // Get the duration of the video, the duration has a second unit
      // It will convert the video duration to second
      final outputMapString = await session.getOutput();
      final outputMap = jsonDecode(outputMapString!) as Map<String, dynamic>;
      final duration = outputMap['format']['duration'];
      //Decode map string into Map
      // return duration['duration'] as int;
      double doubleDurationInSecond = double.parse(duration.toString());
      final durationInMilisecond = (doubleDurationInSecond * 1000).round();
      log('Video duration in milisecond: $durationInMilisecond');
      return durationInMilisecond;
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

//The method for calculating the total offset based on the current video duration in milisecond
double totalVideoOffset(int milisecond) {
  return (milisecond * 60) / 1000;
}

//Method for calculating and assigning the totalOffset that the video will take up,
//the startOffset and endOffset in the actual scrollView based on the previous media.
void calculateStartAndEndOffsetForEachMedia(List<Media> medias) {
  //the next video will be depended on the previous video to calculate the start and end
  for (var i = 1; i < medias.length; i++) {
    final previousMedia = medias[i - 1];
    medias[i].totalOffset = totalVideoOffset(medias[i].durationInMilisecond);
    medias[i].startOffset = previousMedia.endOffset;
    medias[i].endOffset = previousMedia.endOffset + medias[i].totalOffset;
  }
}

Media? getMediaContaingCurrentOffset(
    double currentOffset, List<Media> mediaFiles) {
  for (var media in mediaFiles) {
    if (media.checkCurrentOffsetIsInMediaRange(currentOffset)) {
      return media;
    }
  }
  return null;
}

MediaType getMediaType(String path) {
  List<String> videoTypes = [
    '.mp4',
    '.avi',
    '.mov',
    '.wmv',
    '.mkv',
    '.flv',
    '.webm',
    '.3gp'
  ];
  List<String> imageTypes = [
    '.jpeg',
    '.jpg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
    '.heif,',
    '.heic'
  ];
  //Check the video type
  final extension = '.${path.split('.').last}';
  log('File extension: $extension');
  if (videoTypes.contains(extension)) {
    return MediaType.video;
  } else if (imageTypes.contains(extension)) {
    return MediaType.image;
  }
  return MediaType.video;
  //Check the image type
}
