import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_editor_app/video_editor/models/media.dart';

class ResizableImageFrame extends StatefulWidget {
  const ResizableImageFrame({super.key, required this.imageMedia});

  final Media imageMedia;

  @override
  State<ResizableImageFrame> createState() => _ResizableImageFrameState();
}

class _ResizableImageFrameState extends State<ResizableImageFrame> {
  final ValueNotifier<bool> _isShowIndicator = ValueNotifier(false);
  final ValueNotifier<double> _originalImageWidth = ValueNotifier(60);
  final ValueNotifier<int> _itemCount = ValueNotifier(2);

  void _onResizeImage(DragUpdateDetails details) {
    _originalImageWidth.value += details.delta.dx;
    if (_originalImageWidth.value < 60) {
      _originalImageWidth.value = 60;
    }
    log('current width of the image frame: ${_originalImageWidth.value}');
    //60 is the default width of an image frame
    final numberOfItem = _originalImageWidth.value ~/ 60;
    final reminder = _originalImageWidth.value % 60;
    log('The number of items in image frame by integer: $numberOfItem, Reminder: $reminder');
    _itemCount.value = numberOfItem + 1;
    log('Item count in image frame: ${_itemCount.value}');
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
                        child: ValueListenableBuilder(
                            valueListenable: _itemCount,
                            builder: (context, itemCount, child) {
                              return ListView.builder(
                                itemCount: itemCount,
                                physics: const NeverScrollableScrollPhysics(),
                                addRepaintBoundaries: false,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) => Image.file(
                                  widget.imageMedia.file,
                                  fit: BoxFit.cover,
                                  width: 60,
                                ),
                              );
                            }),
                      );
                    });
              }),
        ),
        ValueListenableBuilder(
          valueListenable: _isShowIndicator,
          builder: (context, isShowIndicator, child) {
            return isShowIndicator
                ? GestureDetector(
                    onTap: () =>
                        _isShowIndicator.value = !_isShowIndicator.value,
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
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
