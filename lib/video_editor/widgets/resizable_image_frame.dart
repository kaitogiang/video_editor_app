import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

class ResizableImageFrame extends StatefulWidget {
  const ResizableImageFrame({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<ResizableImageFrame> createState() => _ResizableImageFrameState();
}

class _ResizableImageFrameState extends State<ResizableImageFrame> {
  final ValueNotifier<bool> _isShowIndicator = ValueNotifier(false);
  final ValueNotifier<double> _originalImageWidth = ValueNotifier(60);
  int itemCount = 2;

  void _onResizeImage(DragUpdateDetails details) {
    _originalImageWidth.value += details.delta.dx;
    if (_originalImageWidth.value < 60) {
      _originalImageWidth.value = 60;
    }
    log('current width of the image frame: ${_originalImageWidth.value}');
    final numberOfItem = _originalImageWidth.value ~/ 100;
    final reminder = _originalImageWidth.value % 100;
    log('The number of items in image frame by integer: $numberOfItem, Reminder: $reminder');
    itemCount = numberOfItem + 1;
    log('Item count in image frame: $itemCount');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            _isShowIndicator.value = !_isShowIndicator.value;
          },
          child: ValueListenableBuilder(
              valueListenable: _originalImageWidth,
              builder: (context, originalImageWidth, child) {
                return ValueListenableBuilder(
                    valueListenable: _isShowIndicator,
                    builder: (context, isShowIndicator, child) {
                      return Container(
                        width: originalImageWidth,
                        height: 50,
                        decoration: isShowIndicator
                            ? const BoxDecoration(
                                border: Border.fromBorderSide(
                                BorderSide(color: Colors.white, width: 2),
                              ))
                            : null,
                        child: ListView.builder(
                          itemCount: itemCount,
                          physics: const NeverScrollableScrollPhysics(),
                          addRepaintBoundaries: false,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) => Image.file(
                            widget.imageFile,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    });
              }),
        ),
        ValueListenableBuilder(
          valueListenable: _isShowIndicator,
          builder: (context, isShowIndicator, child) {
            return GestureDetector(
              onTap: () => _isShowIndicator.value = !_isShowIndicator.value,
              child: ValueListenableBuilder(
                  valueListenable: _originalImageWidth,
                  builder: (context, originalImageWidth, child) {
                    return Container(
                      width: originalImageWidth,
                      height: 50,
                      alignment: Alignment.centerRight,
                      decoration: const BoxDecoration(
                          border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 3),
                      )),
                      child: GestureDetector(
                        onHorizontalDragUpdate: _onResizeImage,
                        child: Container(
                          height: 50,
                          width: 15,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.only(left: 4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Container(
                            height: 20,
                            width: 5,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
            );
          },
        ),
      ],
    );
  }
}
