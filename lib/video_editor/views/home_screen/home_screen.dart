import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_editor_app/video_editor/utils/shared_method.dart';
import 'package:video_editor_app/video_editor/widgets/add_text_form.dart';
import 'package:video_editor_app/video_editor/widgets/bottom_modal.dart';
import 'package:video_editor_app/video_editor/widgets/select_options.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              log('Saving the edited video');
              _buildOptionDialog(context);
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
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                  ),
                ),
              ),
            ],
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
                  onPressed: () {
                    log('Open the options');
                    //Showing the bottom sheet to show the options
                    _buildOptionDialog(context);
                  },
                ),
                //The button for adding the text
                ActionButton(
                  svgIconPath: 'assets/icons/add_text_icon.svg',
                  onPressed: () {
                    log('Showing the dialog for adding text');
                    _buildAddTextDialog(context);
                  },
                ),
                //The button for adding the audio
                ActionButton(
                  svgIconPath: 'assets/icons/music_note_icon.svg',
                  onPressed: () {
                    log('Showing the dialog for adding audio');
                    showLoadingStatus(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<dynamic> _buildAddTextDialog(BuildContext context) {
    return showBottomDialog(
      context: context,
      heightFactor: 0.85,
      widthFactor: 1,
      child: const AddTextForm(),
    );
  }

  Future<dynamic> _buildOptionDialog(BuildContext context) {
    return showBottomDialog(
      context: context,
      heightFactor: 0.71,
      child: SelectOptions(
        options: {
          'Take photo': _takePhotoAction,
          'Choose image from gallery': _selectImageFromGallery,
          'DreamWeaiver Gallery': () {
            log('DreamWeaiver Gallery');
          },
          'Choose video from gallery': _selectVideoFromGallery,
          'Record video': _recordVideo,
          'AI Images': () {
            log('AI Images');
          }
        },
      ),
    );
  }
}

//Methods for handling the selected option
Future<void> _takePhotoAction() async {
  log('Take photo from the camera directly');
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.camera);
  if (image != null) {
    //Do something here
    log('Image path: ${image.path}');
  }
}

Future<void> _selectImageFromGallery() async {
  log('Select image from gallery');
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    //Do something here
    log('Image path in the gallery: ${image.path}');
  }
}

Future<void> _selectVideoFromGallery() async {
  final picker = ImagePicker();
  final video = await picker.pickVideo(source: ImageSource.gallery);
  if (video != null) {
    //Do something here
    log('Video path in the gallery is: ${video.path}');
  }
}

Future<void> _recordVideo() async {
  final picker = ImagePicker();
  final video = await picker.pickVideo(source: ImageSource.camera);
  if (video != null) {
    //Do something here
    log('Recoreded video path : ${video.path}');
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.svgIconPath,
    required this.onPressed,
  });

  final String svgIconPath;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.onPrimary,
          foregroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          fixedSize: const Size.square(20)),
      onPressed: onPressed,
      icon: SvgPicture.asset(
        svgIconPath,
      ),
    );
  }
}
