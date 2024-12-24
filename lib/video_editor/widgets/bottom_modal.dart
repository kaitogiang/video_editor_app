import 'package:flutter/material.dart';

class ModalBottomSheet extends StatelessWidget {
  const ModalBottomSheet(
      {super.key,
      required this.child,
      this.heightFactor = 0.75,
      this.widthFactor = 0.95});

  final Widget child;
  final double heightFactor;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      widthFactor: widthFactor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: child,
      ),
    );
  }
}

Future<dynamic> showBottomDialog({
  required BuildContext context,
  required Widget child,
  double heightFactor = 0.75,
  double widthFactor = 0.95,
}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    sheetAnimationStyle: AnimationStyle(
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 300),
      reverseCurve: Curves.easeInOut,
      reverseDuration: const Duration(milliseconds: 300),
    ),
    backgroundColor: Colors.transparent,
    builder: (context) => ModalBottomSheet(
      heightFactor: heightFactor,
      widthFactor: widthFactor,
      child: child,
    ),
  );
}
