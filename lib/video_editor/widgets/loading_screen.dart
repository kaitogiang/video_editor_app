import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(35),
        decoration: const BoxDecoration(
            color: Color(0xFF262626),
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: const CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}
