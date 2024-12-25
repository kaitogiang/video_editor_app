import 'package:flutter/material.dart';

class DefaultVideoEditorScreen extends StatelessWidget {
  const DefaultVideoEditorScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
            ),
            child: Container(),
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
    );
  }
}