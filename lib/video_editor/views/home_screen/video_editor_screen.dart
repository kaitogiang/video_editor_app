import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key, required this.controller});

  final VideoEditorController controller;

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final double height = 60;

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          widget.controller,
          widget.controller.video,
        ]),
        builder: (context, child) {
          final int duration = widget.controller.videoDuration.inSeconds;
          final double pos = widget.controller.trimPosition * duration;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60 / 4),
            child: Row(
              children: [
                Text(formatter(Duration(seconds: pos.toInt()))),
                const Expanded(child: SizedBox()),
                AnimatedOpacity(
                  opacity: widget.controller.isTrimming ? 1 : 0,
                  duration: kThemeAnimationDuration,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatter(widget.controller.startTrim)),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(formatter(widget.controller.endTrim)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(vertical: height / 4),
        child: TrimSlider(
          controller: widget.controller,
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: widget.controller,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      )
    ];
  }

  Widget _coverSelection() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          child: CoverSelection(
            controller: widget.controller,
            size: height + 10,
            quantity: 8,
            selectedCoverBuilder: (cover, size) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  cover,
                  Icon(
                    Icons.check_circle,
                    color: const CoverSelectionStyle().selectedBorderColor,
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              //Showing the NavBar later here
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Expanded(
                        //Using TabBarView to show the two screen, the first one is the preview video screen and the rest is crop area
                        //There will be a button to switch between the two sreen, for instance, a crop button.
                        //When the user click on it, it will switch to the scrop screen and allow user to crop the video
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                //The widget that will be showed the crop area overlapped the video
                                //The user can see the desired crop area.
                                CropGridViewer.preview(
                                  controller: widget.controller,
                                ),
                                AnimatedBuilder(
                                  animation: widget.controller.video,
                                  builder: (context, child) => AnimatedOpacity(
                                    opacity:
                                        widget.controller.isPlaying ? 0 : 1,
                                    duration: kThemeAnimationDuration,
                                    child: GestureDetector(
                                      onTap: widget.controller.video.play,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            //Showing static image as the cover image and if the user scroll the
                            //video frame, this image will be changed as well
                            CoverViewer(controller: widget.controller)
                          ],
                        ),
                      ),
                      //Showing the below section
                      Container(
                        height: 200,
                        margin: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: [
                            const TabBar(
                              tabs: [
                                //The first Button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(Icons.content_cut),
                                    ),
                                    Text('Trim'),
                                  ],
                                ),
                                //The second button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(Icons.video_label),
                                    ),
                                    Text('Cover')
                                  ],
                                ),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: _trimSlider(),
                                  ),
                                  _coverSelection()
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
