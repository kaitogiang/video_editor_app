import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:video_editor/video_editor.dart';
import 'package:video_editor_app/video_editor/utils/shared_method.dart';
import 'package:video_editor_app/video_editor/widgets/action_button.dart';
import 'package:video_editor_app/video_editor/utils/shared_method.dart';
import 'package:video_editor_app/video_editor/widgets/video_frame.dart';

class VideoEditorPreviewScreen extends StatefulWidget {
  const VideoEditorPreviewScreen({
    super.key,
    // required this.controller,
    required this.videos,
  });

  // final VideoEditorController controller;
  final List<File> videos;

  @override
  State<VideoEditorPreviewScreen> createState() =>
      _VideoEditorPreviewScreenState();
}

class _VideoEditorPreviewScreenState extends State<VideoEditorPreviewScreen> {
  final double height = 60;
  final StreamController<int> _timeLineController = StreamController<int>();
  final StreamController<double> _positionStreamController =
      StreamController<double>();
  final List<String> imagePaths = [];

  final ScrollController _editorScrollController = ScrollController();
  late VideoEditorController videoEditorController;
  @override
  void initState() {
    super.initState();
    //When the user choose the first video to edit, take this video and initialize the video editor controller
    final file = widget.videos[0];
    //Use the first video in the video list for the video editor controller
    videoEditorController = VideoEditorController.file(
      file,
      minDuration: const Duration(seconds: 1),
      maxDuration: const Duration(seconds: 30),
    );
    videoEditorController
        .initialize(aspectRatio: 9 / 16)
        .then((_) => setState(() {
              log('Calling setState when initializing video Controller');
            }))
        .catchError((error) {
      log('Error initializing video editor: $error');

      Navigator.pop(context);
    }, test: (e) => e is VideoMinDurationError);
    log('Video editor controller is initialized: ${videoEditorController.initialized}');
    log('Controller status: ${videoEditorController.initialized}');
    _timeLineController.add(0);
    videoEditorController.video.addListener(() async {
      final position = await videoEditorController.video.position;
      log('Video position: ${position?.inSeconds}');
      log('Current video duration: ${position?.abs()}');
      _timeLineController.add(position!.inSeconds);
      _updateCurrentPosition();
    });
    _startExtractingFrames(widget.videos[0].path);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startExtractingFrames(String videoPath) async {
    log('Starting extract frames');
    // String videoPath = widget.videos[0].path;
    await for (String imagePath in extractVideoFrameStream(videoPath)) {
      setState(() {
        imagePaths.add(imagePath);
      });
    }
  }

  //Building the timeline frames using the imagePath list. This list will contain
  //all of the images to render for the user. When choosing new file, use the
  //_startExtractingFrames method for extract a specific video frames
  Widget _buildVideoTimeLineWithFrames() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            const SizedBox(
              height: 50,
              width: 180,
            ),
            // ...imagePaths.map((path) {
            //   return Container(
            //     width: 100,
            //     height: 50,
            //     margin: const EdgeInsets.symmetric(horizontal: 2.0),
            //     child: Image.file(
            //       File(path),
            //       fit: BoxFit.cover,
            //     ),
            //   );
            // }).toList()
            VideoFrame(file: widget.videos[0]),
          ],
        ),
      ),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  void _updateCurrentPosition() {
    if (videoEditorController.isPlaying) {
      //Push the current posiion to the stream
      double currentPosition = videoEditorController.videoPosition.inSeconds /
          videoEditorController.videoDuration.inSeconds;
      _positionStreamController.sink.add(currentPosition);
    }
  }

  //Showing the video duration
  // Widget _buildTimeLineDuration(int second, int maxSecond) {
  //   final duration = Duration(seconds: second);
  //   final maxDuration = Duration(seconds: maxSecond);
  //   final formattedDuration = duration.toString().split('.')[0];
  //   final formattedMaxDuration = maxDuration.toString().split('.')[0];

  //   return Stack(
  //     children: [
  //       //Background of the timeline
  //       Container(
  //         width: MediaQuery.of(context).size.width,
  //         height: 50,
  //         color: Colors.black12,
  //       ),

  //       // Text(
  //       //   '$formattedDuration / $formattedMaxDuration',
  //       //   style: const TextStyle(
  //       //     color: Colors.white,
  //       //   ),
  //       // ),
  //     ],
  //   );
  // }

  //Build the video timeline that will automatically update the UI when the video
  //is playing
  // Widget _buildTimeLine() {
  //   final maxSecond = videoEditorController.videoDuration.inSeconds;
  //   return StreamBuilder<int>(
  //       stream: _timeLineController.stream,
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return const Text('Waiting');
  //         } else if (!snapshot.hasData) {
  //           return const Text('No data, wating');
  //         }
  //         final random = DateTime.now().second;
  //         return Column(
  //           children: [
  //             Container(
  //               width: MediaQuery.of(context).size.width,
  //               height: height,
  //               decoration: BoxDecoration(
  //                 color: Colors.grey[300],
  //               ),
  //               margin: EdgeInsets.symmetric(horizontal: height / 4),
  //               child: _buildTimeLineDuration(
  //                 snapshot.data!,
  //                 maxSecond,
  //               ),
  //             ),
  //           ],
  //         );
  //       });
  // }

  // Widget _buildVideoTimeLine() {
  //   return StreamBuilder<double>(
  //     stream: _positionStreamController.stream,
  //     builder: (context, snapshot) {
  //       double currentPosition = snapshot.data ?? 0.0;
  //       final duration = videoEditorController.videoDuration.inSeconds;
  //       final double positionInseconds = currentPosition * duration * 15;
  //       return Container(
  //         width: MediaQuery.of(context).size.width,
  //         height: 50,
  //         color: Colors.green[300],
  //         child: Stack(
  //           children: [
  //             Container(
  //               width: MediaQuery.of(context).size.width,
  //               height: 50,
  //               color: Colors.black12,
  //             ),
  //             Positioned(
  //               left: positionInseconds,
  //               child: Container(
  //                 width: 5,
  //                 height: 50,
  //                 color: Colors.red,
  //               ),
  //             )
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // List<Widget> _trimSlider() {
  //   return [
  //     AnimatedBuilder(
  //       //Use Listenable.merge to observe both widget.controller and widget.controller.vido
  //       //concurrently
  //       animation: Listenable.merge([
  //         videoEditorController,
  //         videoEditorController.video,
  //       ]),
  //       builder: (context, child) {
  //         //Extract the maximum duration of the video
  //         final int duration = videoEditorController.videoDuration.inSeconds;
  //         final double pos = videoEditorController.trimPosition * duration;
  //         log('Video Duration in second: $duration');
  //         log('Pos value: $pos');
  //         return Padding(
  //           padding: EdgeInsets.symmetric(horizontal: height / 4),
  //           child: Row(
  //             children: [
  //               //Showing the trim start duration, it's just a label that display
  //               //the current start trim
  //               Text(
  //                 formatter(Duration(seconds: pos.toInt())),
  //                 style: const TextStyle(color: Colors.white),
  //               ),
  //               //Create an empty space that expand all spaces
  //               const Expanded(child: SizedBox()),
  //               //Observe the trimming action to decide when to show
  //               //the start trim duration and end trim duration (such as 00:05 00:16)
  //               AnimatedOpacity(
  //                 //If the user is trimming the slider, so rebuild this widget
  //                 //and set the opacity based on the trimming action
  //                 opacity: videoEditorController.isTrimming ? 1 : 0,
  //                 duration: kThemeAnimationDuration,
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     //Showing the start trim duration
  //                     Text(
  //                       formatter(videoEditorController.startTrim),
  //                       style: const TextStyle(color: Colors.white),
  //                     ),
  //                     const SizedBox(
  //                       width: 10,
  //                     ),
  //                     //showing the end trim duration
  //                     Text(
  //                       formatter(videoEditorController.endTrim),
  //                       style: const TextStyle(color: Colors.white),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //     //Showing the TimeLine for the video
  //     Container(
  //       width: MediaQuery.of(context).size.width,
  //       margin: EdgeInsets.symmetric(vertical: height / 4),
  //       child: TrimSlider(
  //         controller: videoEditorController,
  //         height: height,
  //         horizontalMargin: height / 4,
  //         child: TrimTimeline(
  //           controller: videoEditorController,
  //           padding: const EdgeInsets.only(top: 10),
  //           textStyle: const TextStyle(color: Colors.white),
  //         ),
  //       ),
  //     ),
  //     //Action button below
  //   ];
  // }

  // Widget _coverSelection() {
  //   return SingleChildScrollView(
  //     child: Center(
  //       child: Container(
  //         margin: const EdgeInsets.all(15),
  //         child: CoverSelection(
  //           controller: videoEditorController,
  //           size: height + 10,
  //           quantity: 8,
  //           selectedCoverBuilder: (cover, size) {
  //             return Stack(
  //               alignment: Alignment.center,
  //               children: [
  //                 cover,
  //                 Icon(
  //                   Icons.check_circle,
  //                   color: const CoverSelectionStyle().selectedBorderColor,
  //                 )
  //               ],
  //             );
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              //Showing the NavBar later here
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      //Using TabBarView to show the two screen, the first one is the preview video screen and the rest is crop area
                      //There will be a button to switch between the two sreen, for instance, a crop button.
                      //When the user click on it, it will switch to the scrop screen and allow user to crop the video
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          //The widget that will be showed the crop area overlapped the video
                          //The user can see the desired crop area.
                          // CropGridViewer.preview(
                          //   controller: widget.controller,
                          // ),
                          //The widget for showing the video preview for the user to see
                          CropGridViewer.preview(
                              controller: videoEditorController),

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
                            animation: videoEditorController.video,
                            builder: (context, child) => AnimatedOpacity(
                              opacity: videoEditorController.isPlaying ? 0 : 1,
                              duration:
                                  kThemeAnimationDuration, //kThemeAnimationDuration is a standard constant
                              child: GestureDetector(
                                onTap: videoEditorController.video.play,
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
                    ),
                    //Showing the below section
                    //A container for containing all the widget below such as
                    //TabBar and TimeLine
                    Container(
                      height: 300,
                      // decoration: const BoxDecoration(
                      //   color: Colors.white,
                      // ),
                      margin: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          //In this context, We will use one TabBar for controlling the two
                          //TabBarView above. The first TabBarView for showing the above section,
                          //The second TabBarView for showing the below section
                          //When we click on a specific tab in TabBarView, the both TabBarView will select the
                          //corresponding page index in the TabBarView.
                          const Divider(),
                          // Expanded(
                          //   //Display the two below section, The first is timeline and the second is cover page
                          //   child: Column(
                          //     mainAxisAlignment: MainAxisAlignment.center,
                          //     children: [
                          //       ..._trimSlider(),
                          //       // _buildTimeLine(),
                          //       _buildVideoTimeLine(),
                          //     ],
                          //   ),
                          // )
                          // Expanded(
                          //   child: SingleChildScrollView(
                          //     child: Container(
                          //       decoration: const BoxDecoration(
                          //           // color: Colors.red,
                          //           ),
                          //       child: _buildVideoTimeLine(),
                          //     ),
                          //   ),
                          // )
                          Expanded(
                            child: Stack(
                              children: [
                                //Showing the video timeline preview, autio timeline, Text timeline
                                ListView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _editorScrollController,
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    _buildVideoTimeLineWithFrames(),
                                  ],
                                ),
                                const Positioned.fill(
                                  child: VerticalDivider(
                                    thickness: 2,
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Column(
                                    children: [
                                      //The button for showing the options
                                      ActionButton(
                                        svgIconPath:
                                            'assets/icons/plus_icon.svg',
                                        onPressed: () async {
                                          log('Open the options');
                                          //Showing the bottom sheet to show the options
                                          final file =
                                              await buildOptionDialog(context)
                                                  as File?;
                                          log('file in ActionButton: ${file?.path}');
                                          // _selectedFile.value = file;
                                          //if the selected file is not null, then initialize the video editor controller
                                          if (file != null) {
                                            //Adding the video file to the list
                                            widget.videos.add(file);
                                            log('New video length list: ${widget.videos.length}');
                                            //Navigate to the video editor screen
                                          }
                                        },
                                      ),
                                      //The button for adding the text
                                      ActionButton(
                                        svgIconPath:
                                            'assets/icons/add_text_icon.svg',
                                        onPressed: () {
                                          log('Showing the dialog for adding text');
                                          // _buildAddTextDialog(context);
                                        },
                                      ),
                                      //The button for adding the audio
                                      ActionButton(
                                        svgIconPath:
                                            'assets/icons/music_note_icon.svg',
                                        onPressed: () {
                                          log('Showing the dialog for adding audio');
                                          // showLoadingStatus(context);
                                          //Upload audio to the app
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
