import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:video_editor/ui/video_viewer.dart';
import 'package:video_editor/video_editor.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key, required this.controller});

  final VideoEditorController controller;

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final double height = 60;

  @override
  void initState() {
    super.initState();
    log('Controller status: ${widget.controller.initialized}');
  }

  @override
  void dispose() {
    super.dispose();
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        //Use Listenable.merge to observe both widget.controller and widget.controller.vido
        //concurrently
        animation: Listenable.merge([
          widget.controller,
          widget.controller.video,
        ]),
        builder: (context, child) {
          //Extract the maximum duration of the video
          final int duration = widget.controller.videoDuration.inSeconds;
          final double pos = widget.controller.trimPosition * duration;
          log('Video Duration in second: $duration');
          log('Pos value: $pos');
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(
              children: [
                //Showing the trim start duration, it's just a label that display
                //the current start trim
                Text(formatter(Duration(seconds: pos.toInt()))),
                //Create an empty space that expand all spaces
                const Expanded(child: SizedBox()),
                //Observe the trimming action to decide when to show
                //the start trim duration and end trim duration (such as 00:05 00:16)
                AnimatedOpacity(
                  //If the user is trimming the slider, so rebuild this widget
                  //and set the opacity based on the trimming action
                  opacity: widget.controller.isTrimming ? 1 : 0,
                  duration: kThemeAnimationDuration,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //Showing the start trim duration
                      Text(formatter(widget.controller.startTrim)),
                      const SizedBox(
                        width: 10,
                      ),
                      //showing the end trim duration
                      Text(formatter(widget.controller.endTrim)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      //Showing the TimeLine for the video
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
                            //Display the video player with the play button overlapped
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                //The widget that will be showed the crop area overlapped the video
                                //The user can see the desired crop area.
                                // CropGridViewer.preview(
                                //   controller: widget.controller,
                                // ),
                                //The widget for showing the video preview for the user to see
                                VideoViewer(controller: widget.controller),
                                //Building the player Icon that allows user click on it
                                //By default, the icon is visile and the video is not play.
                                //When the video is playing, the widget.controller.isPlayer return true,
                                //so the icon will be transparent by setting the opacity to zero.
                                //The value range of opacity from 0 to 1, 0 is fully transparent, 1 is fully visible
                                AnimatedBuilder(
                                  //The animation property of AnimatedBuilder is used to specify the Animation or AnimationController instance
                                  //which will be observed by the AnimatedBuilder. If the animation value is changed
                                  //The builder property of AnimatedBuilder will require a new build call and rebuild Widget
                                  //In this context, we will observe the video property of VideoEditorController.
                                  //Whenever the video is playing or stopping, it will trigger the rebuild
                                  animation: widget.controller.video,
                                  builder: (context, child) => AnimatedOpacity(
                                    opacity:
                                        widget.controller.isPlaying ? 0 : 1,
                                    duration:
                                        kThemeAnimationDuration, //kThemeAnimationDuration is a standard constant
                                    child: GestureDetector(
                                      onTap: widget.controller.video.play,
                                      child: Container(
                                        width: 100,
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
                      //A container for containing all the widget below such as
                      //TabBar and TimeLine
                      Container(
                        height: 300,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        margin: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: [
                            //In this context, We will use one TabBar for controlling the two
                            //TabBarView above. The first TabBarView for showing the above section,
                            //The second TabBarView for showing the below section
                            //When we click on a specific tab in TabBarView, the both TabBarView will select the
                            //corresponding page index in the TabBarView.
                            const TabBar(
                              tabs: [
                                //The first Button, the Trim button for trim the video
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
                                //The second button, the cover button for showing each frame in
                                //the video.
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
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
                              //Display the two below section, The first is timeline and the second is cover page
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  //Showing the timeline that center the TrimSlider
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: _trimSlider(),
                                  ),
                                  //Showing the cover selection
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
