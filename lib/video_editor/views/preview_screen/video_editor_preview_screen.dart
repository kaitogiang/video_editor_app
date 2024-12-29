import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:video_editor/video_editor.dart';
import 'package:video_editor_app/video_editor/models/media.dart';
import 'package:video_editor_app/video_editor/utils/shared_method.dart';
import 'package:video_editor_app/video_editor/widgets/action_button.dart';
import 'package:video_editor_app/video_editor/utils/shared_method.dart';
import 'package:video_editor_app/video_editor/widgets/video_frame.dart';
import 'package:video_editor_app/video_editor/widgets/video_frame_marker.dart';

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
  final StreamController<double> _positionStreamController =
      StreamController<double>();
  final List<String> imagePaths = [];

  final ScrollController _editorScrollController = ScrollController();
  late ValueNotifier<VideoEditorController> videoEditorController =
      ValueNotifier(VideoEditorController.file(
    widget.videos[0],
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 3600),
  ));
  VideoEditorController? _nextVideoEditorController;
  final ValueNotifier<List<File>> _filesNotifier = ValueNotifier([]);
  //Observe the current video playing index
  int currentVideoIndex = 0;
  //Observe the current offset that the previous video has scrolled to
  double currentScrollOffset = 0;

  Timer? positionTimer;
  bool isPressPlayVideo = true;
  bool hasReachedEnd = false;

  //List of media for storing the media file;
  List<Media> mediaFiles = [];

  @override
  void initState() {
    super.initState();
    //When the user choose the first video to edit, take this video and initialize the video editor controller
    final file = widget.videos[0];
    //Use the first video in the video list for the video editor controller
    // videoEditorController = VideoEditorController.file(
    //   file,
    //   minDuration: const Duration(seconds: 1),
    //   maxDuration: const Duration(seconds: 3600),
    // );
    videoEditorController.value.initialize().then((_) {
      setState(() {
        log('Calling setState when initializing video Controller');
      });
      videoEditorController.value.video.setLooping(false);
      videoEditorController.value.video.addListener(_videoEditorListener);

      //Calculating the totalOffset, start and end offset for the first video
      final maxDurationInMilisecond =
          videoEditorController.value.videoDuration.inMilliseconds;
      final totalOffset = totalVideoOffset(maxDurationInMilisecond);
      final Media media = Media(
        file: file,
        durationInMilisecond: maxDurationInMilisecond,
        totalOffset: totalOffset,
        startOffset: 0,
        endOffset: totalOffset,
      );
      mediaFiles.add(media);
    }).catchError((error) {
      log('Error initializing video editor: $error');
      Navigator.pop(context);
    }, test: (e) => e is VideoMinDurationError);
    //Adding the first file to the fileNotifer for observe the state of the fileNotifer list
    _filesNotifier.value = [file];
    log('Video editor controller is initialized: ${videoEditorController.value.initialized}');
    log('Controller status: ${videoEditorController.value.initialized}');

    //Observe the _editScrollController
    // _editorScrollController.addListener(() async {
    //   // log('Current offset: ${_editorScrollController.offset}');
    //   //If the user has scroll 60 offset, we will update the video position to next 1 second
    //   //60 offset = 1 second = 1000 milisecond
    //   if (videoEditorController.isPlaying) return;

    //   final newVideoPosition =
    //       (_editorScrollController.offset.toInt() * 1000 / 60).toInt();
    //   videoEditorController.video
    //       .seekTo(Duration(milliseconds: newVideoPosition));
    // });
    _editorScrollController.addListener(_scrollListener);
  }

  //A listener for observing the current videoEditorController
  void _videoEditorListener() async {
    //Observe every 100 milisecond
    if (videoEditorController.value.isPlaying) {
      _startPositionTimer();
    } else {
      _stopPositionTimer();
    }
    //Check wheather the video is reach the end or not
    if (videoEditorController.value.video.value.isCompleted) {
      log('Reach the end....: ${videoEditorController.value.isPlaying}');
      _playNextVideo();
    }
  }

  void _scrollListener() async {
    final currentOffset = _editorScrollController.offset;
    // currentScrollOffset = currentOffset;
    log('Current offset: ${_editorScrollController.offset}');
    //If the user has scroll 60 offset, we will update the video position to next 1 second
    //60 offset = 1 second = 1000 milisecond
    if (videoEditorController.value.isPlaying) return;
    //Check which the media contains the current offset in the list
    //Observing the scroll position to recognize the current media
    final currentMedia = getMediaContaingCurrentOffset(
        _editorScrollController.offset, mediaFiles);
    if (currentMedia != null) {
      log('Has scrolled to the media: ${currentMedia.toString()}');
      final currentMediaIndex = mediaFiles.indexOf(currentMedia);
      _switchVideoEditorController(currentMediaIndex);
      final newVideoPosition =
          currentMedia.calculateCurrentPosition(currentOffset).toInt();
      //Seeking to the video position based on the current video media
      videoEditorController.value.video
          .seekTo(Duration(milliseconds: newVideoPosition));
    }
    // final newVideoPosition =
    //     (_editorScrollController.offset.toInt() * 1000 / 60).toInt();
    // videoEditorController.value.video
    //     .seekTo(Duration(milliseconds: newVideoPosition));
  }

  //The method for switching the current video editor controller and display the
  //specific video for the user based on the current video index.
  //The current video index is calculated based on the scroll position. When the user has crolled
  //to the area of the specific media, it will change the corresponding current video index.
  //So we can use this index to intialize the current video editor controller, and then
  //seeking to the video position.
  void _switchVideoEditorController(int currentMediaIndex) {
    //If the current media index is different from the current video index,
    //we will inialize the corresponding video editor controller for the current media
    //and then update the current video index similar to current media index.
    //In this checking, we need to check wheather the _nextEditorController is null or not
    //If it is null, we will initialize it. Because the condition currentVideoIndex and currentMediaIndex
    //are sastified many times and so it will leak the memory and make the app stop, by checking
    //When listen to the scrollview, it will be called many times, so the currentVideoIndex != currentMediaIndex condition
    //will be true many times and so the _nextEditorController will be initalized many times as well, and this
    //is the reason why the app will stop immidiately. Because the initialize method is async, so
    //it need a period of time to initiliaze and call setState is the final step. So at the first time
    //the currentVideoIndex and currentMediaIndex and _nextEditorController are sastified, so
    //the _nextVideoEditorController is assigned and not null. So if the listenr triggered this method
    //again, the _nextVideoEditroController != null and so the if statement will not triggered, and
    //we won't leak the memory at this time.
    if (currentVideoIndex != currentMediaIndex &&
        _nextVideoEditorController == null) {
      // //update the last scroll offset for the previous video
      // currentScrollOffset = mediaFiles[currentMediaIndex].endOffset;
      //Assigning the VideoEditorController and intializing it
      _nextVideoEditorController = VideoEditorController.file(
        mediaFiles[currentMediaIndex].file,
        minDuration: const Duration(seconds: 1),
        maxDuration: const Duration(seconds: 3600),
      );
      _nextVideoEditorController!.initialize().then((_) {
        setState(() {
          videoEditorController.value.video
              .removeListener(_videoEditorListener);
          videoEditorController.value = _nextVideoEditorController!;
          videoEditorController.value.video.addListener(_videoEditorListener);
          videoEditorController.value.video.setLooping(false);
          _nextVideoEditorController = null;
          currentVideoIndex = currentMediaIndex;
          log('The current video editor controller has inialized successfully in _switchVideoEditorController');
        });
      }).catchError((error) {
        log('Erorr in _switchVideoEditorController: $error');
      });
    } else {
      log('The currentVideoIndex and currentMediaIndex are the same, so dont need to create a controller');
    }
  }

  void _playNextVideo() async {
    //Increase the currentVideoIndex that show the next video in the file list
    //Initializing the nextEditorController
    if (_nextVideoEditorController == null) {
      log('The last offset is $currentScrollOffset');
      //If the index is valid and the list contains the file at index, try to
      //initialize it
      if (currentVideoIndex + 1 < _filesNotifier.value.length) {
        currentVideoIndex++;
        //Assign the last offset that the video has scrolled to
        currentScrollOffset = _editorScrollController.offset;
        log('currentScrollOffset --->: $currentScrollOffset');
        final nextFile = _filesNotifier.value[currentVideoIndex];
        log('Next file path: ${_filesNotifier.value[currentVideoIndex].path}');
        _nextVideoEditorController = VideoEditorController.file(
          nextFile,
          minDuration: const Duration(seconds: 1),
          maxDuration: const Duration(seconds: 3600),
        );
        _nextVideoEditorController!.initialize().then((_) {
          setState(() {
            videoEditorController.value.video
                .removeListener(_videoEditorListener);
            videoEditorController.value = _nextVideoEditorController!;
            videoEditorController.value.video.addListener(_videoEditorListener);
            videoEditorController.value.video.setLooping(false);
            videoEditorController.value.video.play();
            _nextVideoEditorController = null;
            log('next video is playing');
          });
        }).catchError((error) {
          log('Error in nextEditorController: $error');
        });
      }
    } else {
      //Print out the message indicate the controller has been initilized
      log('The nextEditorController has been initialized');
    }
  }

  @override
  void dispose() {
    videoEditorController.dispose();
    super.dispose();
  }

  //Repeat the timer each 100 milisecond and get the current video position in milisecond
  void _startPositionTimer() {
    _stopPositionTimer();
    positionTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      final position = await videoEditorController.value.video.position;
      if (position != null) {
        log('Current Position: ${position.inMilliseconds} ms');
        _updateCurrentScrollOffsetByMilisecond(position.inMilliseconds);
      }
    });
  }

  void _stopPositionTimer() {
    positionTimer?.cancel();
    positionTimer = null;
  }

  void _updateCurrentScrollOffset(int videoPositionInSecond) {
    log('videoPositionInSecond: $videoPositionInSecond');
    _editorScrollController.jumpTo(videoPositionInSecond * 60);
    // _editorScrollController.jumpTo(
    //   videoPositionInSecond / 60 * 1000,
    // );
  }

  void _updateCurrentScrollOffsetByMilisecond(int videoPositionInMilisecond) {
    final offset = currentScrollOffset + (videoPositionInMilisecond / 100) * 6;
    _editorScrollController.jumpTo(offset);
    // _editorScrollController.animateTo(
    //   offset,
    //   duration: const Duration(milliseconds: 100),
    //   curve: Curves.easeInOut,
    // );
  }

  //Building the timeline frames using the imagePath list. This list will contain
  //all of the images to render for the user. When choosing new file, use the
  //_startExtractingFrames method for extract a specific video frames
  Widget _buildVideoTimeLineWithFrames() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Timeline marker
        const VideoFrameMarker(),
        //Video frames
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            children: [
              const SizedBox(
                height: 50,
                width: 180,
              ),
              //When the user adding the new file, rebuilt this section to show the new video timeline
              ValueListenableBuilder(
                  valueListenable: _filesNotifier,
                  builder: (context, fileList, child) {
                    return Row(
                      children: List<Widget>.generate(fileList.length, (index) {
                        return VideoFrame(file: fileList[index]);
                      }),
                    );
                  }),
              Container(
                decoration: const BoxDecoration(color: Color(0xFF0E0E0E)),
                height: 50,
                width: 240,
                child: const Row(
                  children: [
                    SizedBox(
                      width: 30,
                    ),
                    Icon(
                      Icons.fast_forward_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(
                      width: 50,
                    ),
                    Icon(
                      Icons.fast_forward_outlined,
                      color: Colors.white,
                    ),
                    Spacer()
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  // void _updateCurrentPosition() {
  //   if (videoEditorController.value.isPlaying) {
  //     //Push the current posiion to the stream
  //     double currentPosition = videoEditorController.videoPosition.inSeconds /
  //         videoEditorController.videoDuration.inSeconds;
  //     _positionStreamController.sink.add(currentPosition);
  //   }
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
                          ValueListenableBuilder(
                              valueListenable: videoEditorController,
                              builder: (context, videController, child) {
                                log('Triggered rebuild, videController initialization: ${videController.initialized}');
                                //As my knowledge, the CropGridViewer will not updated its controller because
                                //it has an internal state that prevent the update, so when I try to pass the new
                                //video editor controller to this widget, it doen's reflect the changes in the UI
                                //So I have found a solution, that is when the ValueListenableBuilder catch a rebuild event
                                //I will create a new CropGridViwer.preview by passing the new key. If I remain the old key,
                                //It will not create new and will use the old one. So I think this is a good solution
                                //In summary, the solution is to create a new CropGridViewer.preview by passing the new key whenever
                                //the video editor controller has changed.
                                return CropGridViewer.preview(
                                  key: ValueKey(videController),
                                  controller: videController,
                                );
                              }),

                          //Building the player Icon that allows user click on it
                          //By default, the icon is visile and the video is not play.
                          //When the video is playing, the widget.controller.isPlayer return true,
                          //so the icon will be transparent by setting the opacity to zero.
                          //The value range of opacity from 0 to 1, 0 is fully transparent, 1 is fully visible
                          ValueListenableBuilder(
                              valueListenable: videoEditorController,
                              builder: (context, videoController, child) {
                                return AnimatedBuilder(
                                  //The animation property of AnimatedBuilder is used to specify the Animation or AnimationController instance
                                  //which will be observed by the AnimatedBuilder. If the animation value is changed
                                  //The builder property of AnimatedBuilder will require a new build call and rebuild Widget
                                  //In this context, we will observe the video property of VideoEditorController.
                                  //Whenever the video is playing or stopping, it will trigger the rebuild
                                  animation: videoController.video,
                                  builder: (context, child) => AnimatedOpacity(
                                    opacity: videoController.isPlaying ? 0 : 1,
                                    duration:
                                        kThemeAnimationDuration, //kThemeAnimationDuration is a standard constant
                                    child: GestureDetector(
                                      onTap: () {
                                        if (isPressPlayVideo) {
                                          videoController.video.play();
                                          isPressPlayVideo = false;
                                        } else {
                                          videoController.video.pause();
                                          isPressPlayVideo = true;
                                        }
                                      },
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
                                );
                              }),
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
                                FractionallySizedBox(
                                  widthFactor: 0.9,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    controller: _editorScrollController,
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      _buildVideoTimeLineWithFrames(),
                                    ],
                                  ),
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
                                            _filesNotifier.value = [
                                              ..._filesNotifier.value,
                                              file
                                            ];
                                            //Get the duration in milisecond of the video
                                            final durationInMilisecond =
                                                await getVideoDurationInMilisecond(
                                                    file.path);
                                            //Creating new media file for the new imported video
                                            Media media = Media(
                                              file: file,
                                              durationInMilisecond:
                                                  durationInMilisecond,
                                            );
                                            //Add it to the mediaList
                                            mediaFiles.add(media);
                                            //Reassign the totalOffset, start and end offset
                                            calculateStartAndEndOffsetForEachMedia(
                                                mediaFiles);
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
                                          if (mediaFiles.length > 1) {
                                            log('The first video information is: ${mediaFiles[0].toString()}');
                                            log('Next video information is: ${mediaFiles[1].toString()}');
                                          }
                                          log('Current video index: $currentVideoIndex');
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
