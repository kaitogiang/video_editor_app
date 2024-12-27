import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
