import 'dart:io';

import 'package:flutter/material.dart';

class DefaultVideoFrame extends StatelessWidget {
  const DefaultVideoFrame({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Image.file(File(imagePath));
  }
}
