import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_editor_app/video_editor/models/media.dart';
import 'package:video_editor_app/video_editor/utils/shared_method.dart';
import 'package:video_editor_app/video_editor/views/home_screen/default_video_editor_screen.dart';
import 'package:video_editor_app/video_editor/views/home_screen/video_editor_screen.dart';
import 'package:video_editor_app/video_editor/views/preview_screen/video_editor_preview_screen.dart';
import 'package:video_editor_app/video_editor/widgets/action_button.dart';
import 'package:video_editor_app/video_editor/widgets/add_text_form.dart';
import 'package:video_editor_app/video_editor/widgets/bottom_modal.dart';
import 'package:video_editor_app/video_editor/widgets/loading_screen.dart';
import 'package:video_editor_app/video_editor/widgets/select_options.dart';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? file;
  final ValueNotifier<File?> _selectedFile = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              log('Saving the edited video');
              // _buildOptionDialog(context, file);
              log('Selected file is: ${file?.path}');
            },
            icon: const Icon(Icons.save),
          ),
          IconButton(
            onPressed: () {
              log('Close editor');
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Stack(
        children: [
          //The main content
          ValueListenableBuilder(
            valueListenable: _selectedFile,
            builder: (context, selectedFile, child) {
              return selectedFile == null
                  ? const FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: DefaultVideoEditorScreen(),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                      color: Colors.white,
                    ));
            },
          ),
          //the floating action button with custom position
          Positioned(
            right: 10,
            top: 440,
            child: Column(
              children: [
                //The button for showing the options
                ActionButton(
                  svgIconPath: 'assets/icons/plus_icon.svg',
                  onPressed: () async {
                    log('Open the options');
                    //Showing the bottom sheet to show the options
                    final file = await buildOptionDialog(context) as File?;
                    _selectedFile.value = file;
                    //if the selected file is not null, then initialize the video editor controller
                    if (file != null) {
                      //Creating a media object to hold the media file
                      final mediaType = getMediaType(file.path);
                      log(mediaType.toString());
                      //Get the duration in milisecond of the video
                      final durationInMilisecond =
                          await getVideoDurationInMilisecond(file.path);
                      //Creating new media file for the new imported video
                      Media media = Media(
                        file: file,
                        durationInMilisecond: durationInMilisecond,
                        fileType: mediaType,
                      );
                      //Navigate to the video editor screen
                      Navigator.of(context, rootNavigator: true)
                          .pushReplacement(MaterialPageRoute(
                              builder: (context) =>
                                  VideoEditorPreviewScreen(videos: [media])));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

//   Future<dynamic> _buildAddTextDialog(BuildContext context) {
//     return showBottomDialog(
//       context: context,
//       heightFactor: 0.85,
//       widthFactor: 1,
//       child: const AddTextForm(),
//     );
//   }

//   Future<dynamic> _buildOptionDialog(BuildContext context) async {
//     return showBottomDialog(
//       context: context,
//       heightFactor: 0.71,
//       child: SelectOptions(
//         options: {
//           'Take photo': () async {
//             final file = await _takePhotoAction();
//             log('Selected file in buildOptionDialog: ${file?.path}');
//             Navigator.of(context, rootNavigator: true).pop(file);
//           },
//           'Choose image from gallery': _selectImageFromGallery,
//           'DreamWeaiver Gallery': () {
//             log('DreamWeaiver Gallery');
//           },
//           'Choose video from gallery': () async {
//             final videoFile = await _selectVideoFromGallery();
//             final videoPlayerController = VideoPlayerController.file(videoFile!)
//               ..initialize();
//             log('Video player controller in _buildOptionDialog: ${videoPlayerController.value.duration}');
//             Navigator.of(context, rootNavigator: true).pop(videoFile);
//           },
//           'Record video': _recordVideo,
//           'AI Images': () {
//             log('AI Images');
//           }
//         },
//       ),
//     );
//   }
// }

// //Methods for handling the selected option
// Future<File?> _takePhotoAction() async {
//   log('Take photo from the camera directly');
//   final picker = ImagePicker();
//   final image = await picker.pickImage(source: ImageSource.camera);
//   if (image != null) {
//     //Do something here
//     log('Image path: ${image.path}');
//     return File(image.path);
//   }
//   return null;
// }

// Future<void> _selectImageFromGallery() async {
//   log('Select image from gallery');
//   final picker = ImagePicker();
//   final image = await picker.pickImage(source: ImageSource.gallery);
//   if (image != null) {
//     //Do something here
//     log('Image path in the gallery: ${image.path}');
//     final imageFile = File(image.path);
//   }
// }

// Future<File?> _selectVideoFromGallery() async {
//   final picker = ImagePicker();
//   final video = await picker.pickVideo(source: ImageSource.gallery);
//   if (video != null) {
//     //Do something here
//     log('Video path in the gallery is: ${video.path}');
//     return File(video.path);
//   }
//   return null;
// }

// Future<void> _recordVideo() async {
//   final picker = ImagePicker();
//   final video = await picker.pickVideo(source: ImageSource.camera);
//   if (video != null) {
//     //Do something here
//     log('Recoreded video path : ${video.path}');
//   }
}
