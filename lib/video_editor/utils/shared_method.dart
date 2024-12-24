import 'package:flutter/material.dart';
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
