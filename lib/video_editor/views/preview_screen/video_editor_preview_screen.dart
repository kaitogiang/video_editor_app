import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:video_editor/video_editor.dart';
import 'package:video_editor_app/video_editor/models/media.dart';
import 'package:video_editor_app/video_editor/utils/shared_method.dart';
import 'package:video_editor_app/video_editor/widgets/action_button.dart';
import 'package:video_editor_app/video_editor/utils/shared_method.dart';
import 'package:video_editor_app/video_editor/widgets/resizable_image_frame.dart';
import 'package:video_editor_app/video_editor/widgets/video_frame.dart';
import 'package:video_editor_app/video_editor/widgets/video_frame_marker.dart';

class VideoEditorPreviewScreen extends StatefulWidget {
  const VideoEditorPreviewScreen({
    super.key,
    // required this.controller,
    required this.videos,
  });

  // final VideoEditorController controller;
  final List<Media> videos;

  @override
  State<VideoEditorPreviewScreen> createState() =>
      _VideoEditorPreviewScreenState();
}

class _VideoEditorPreviewScreenState extends State<VideoEditorPreviewScreen> {
  final double height = 60;
  final List<String> imagePaths = [];

  final ScrollController _editorScrollController = ScrollController();
  late ValueNotifier<VideoEditorController> videoEditorController =
      ValueNotifier(VideoEditorController.file(
    widget.videos[0].file,
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 3600),
  ));
  VideoEditorController? _nextVideoEditorController;
  // final ValueNotifier<List<Media>> _filesNotifier = ValueNotifier([]);
  //Observe the playing status of the video
  final ValueNotifier<bool> _isPlayingVideo = ValueNotifier(false);
  //Observe the current video playing index
  int currentVideoIndex = 0;
  //Observe the current offset that the previous video has scrolled to
  double currentScrollOffset = 0;

  Timer? positionTimer;
  bool isPressPlayVideo = true;
  bool hasReachedEnd = false;

  Timer? _scrollTimer;
  final ValueNotifier<bool> _isScrolling = ValueNotifier(false);

  //List of media for storing the media file;
  ValueNotifier<List<Media>> mediaFiles = ValueNotifier([]);

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
      final fileType = getMediaType(file.file.path);
      final Media media = Media(
        file: file.file,
        durationInMilisecond: maxDurationInMilisecond,
        totalOffset: totalOffset,
        startOffset: 0,
        endOffset: totalOffset,
        fileType: fileType,
      );
      mediaFiles.value = [media];
    }).catchError((error) {
      log('Error initializing video editor: $error');
      Navigator.pop(context);
    }, test: (e) => e is VideoMinDurationError);
    //Adding the first file to the fileNotifer for observe the state of the fileNotifer list
    // _filesNotifier.value = [file];
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

    log('The video listener is listening the video even the video is pausing :))');
    // if (!videoEditorController.value.isPlaying) {
    //   log('Dont listen to the video editor controller because the video is not playing');
    //   return;
    // }

    //Initialize the nextEditorController to the next video when the first video is playing at 25% of the total duration
    final totalDuration = videoEditorController.value.videoDuration;
    final currentVideoPosition =
        await videoEditorController.value.video.position;
    if (currentVideoPosition! >= totalDuration * 0.25) {
      if (videoEditorController.value.isPlaying) {
        log('Initialize the nextEditorController in videoEditorListener');
        //Preload the next Editor controller
        _initializeNextEditorController();
      }
    }
    //---------------------------------------

    //Check wheather the video is reach the end or not
    if (videoEditorController.value.video.value.isCompleted) {
      log('Reach the end....: ${videoEditorController.value.isPlaying}');
      //When the video is reach end, jump to the last offset of the video
      // final currentMedia = mediaFiles[currentVideoIndex];
      // _updateCurrentScrollOffsetByMilisecond(currentMedia.durationInMilisecond);
      _isPlayingVideo.value = false;
      // _playNextVideo();
      //When the previous video has reach end, at this time, the nextVideoEditorController has been initialized fully.
      //So we just assign the nextEditorController to the videoEditorController and call setState to the update the UI
      _playNextVideoController();
    }
  }

  void _scrollListener() async {
    //Cancelling the previous Timer to prevent multiple timer
    _scrollTimer?.cancel();

    //Set the _isCrolling = true if the previous scroll status is false
    if (!_isScrolling.value) {
      _isScrolling.value = true;
      log('The user is scrolling the video editor');
    }
    //-------------------------------------------------------
    final currentOffset = _editorScrollController.offset;
    // currentScrollOffset = currentOffset;
    log('Current offset: ${_editorScrollController.offset}');
    //If the user has scroll 60 offset, we will update the video position to next 1 second
    //60 offset = 1 second = 1000 milisecond
    if (videoEditorController.value.isPlaying) return;
    //Check which the media contains the current offset in the list
    //Observing the scroll position to recognize the current media
    final currentMedia = getMediaContaingCurrentOffset(
        _editorScrollController.offset, mediaFiles.value);
    if (currentMedia != null) {
      log('Has scrolled to the media: ${currentMedia.toString()}');
      final currentMediaIndex = mediaFiles.value.indexOf(currentMedia);

      log('Current media index: $currentMediaIndex, current video index: $currentVideoIndex');

      //Switching to next video editor controller after 1 second and prevent the dispose issues when the controller is not
      //initilaized correctly because the user has scrolled very fast
      //Check the current video index and current media index. The current video index will store the previous index which doesn't update immediately. And
      //the current media index is the current index which is updated right away when the user has scrolled to the specific media.
      //When the user has scrolled very fast from index 1 to index 0, the current video index and current media index is different, after the nextEditorController has
      //assinged to the vidoEditorController, the current video index will reassign to the current media index.
      //This way will prevent the intialization many times when the user has scrolled between the two media very fast. In below code,
      //when the user has scrolled very fast between the two media and they continue to scroll and don't stop now. So the _scrollTimer will be cancled and the callback
      //is not called. This action will prevent "The controller has disposed before updating the CoverData". This means the previous controller has been disposed and
      //this controller is used, so it leads to the above error.

      //If the user has scrolled outside the media file, do nothing
      if (currentOffset > mediaFiles.value.last.endOffset) {
        return;
      }

      if (currentMediaIndex == currentVideoIndex) {
        final newVideoPosition =
            currentMedia.calculateCurrentPosition(currentOffset).toInt();
        //Seeking to the video position based on the current media
        videoEditorController.value.video
            .seekTo(Duration(milliseconds: newVideoPosition));
        return;
      }
      _scrollTimer = Timer(const Duration(milliseconds: 500), () {
        _isScrolling.value = false;
        log('The scrolling action has stopped');
        _switchVideoEditorController(currentMediaIndex);
        final newVideoPosition =
            currentMedia.calculateCurrentPosition(currentOffset).toInt();
        //Seeking to the video position based on the current video media
        videoEditorController.value.video
            .seekTo(Duration(milliseconds: newVideoPosition));
      });

      // if (currentMediaIndex != currentVideoIndex) {
      //   _scrollTimer = Timer(const Duration(milliseconds: 200), () {
      //     _isScrolling.value = false;
      //     log('The scrolling action has stopped');
      //     _switchVideoEditorController(currentMediaIndex);
      //     final newVideoPosition =
      //         currentMedia.calculateCurrentPosition(currentOffset).toInt();
      //     //Seeking to the video position based on the current video media
      //     videoEditorController.value.video
      //         .seekTo(Duration(milliseconds: newVideoPosition));
      //   });
      // } else {
      //   //When the current media index and current video index is the same, so we can use the video editor controller to seek to a specific duration in the video
      //   // _switchVideoEditorController(currentMediaIndex);
      //   final newVideoPosition =
      //       currentMedia.calculateCurrentPosition(currentOffset).toInt();
      //   //Seeking to the video position based on the current video media
      //   videoEditorController.value.video
      //       .seekTo(Duration(milliseconds: newVideoPosition));
      // }
    }
    // final newVideoPosition =
    //     (_editorScrollController.offset.toInt() * 1000 / 60).toInt();
    // videoEditorController.value.video
    //     .seekTo(Duration(milliseconds: newVideoPosition));
  }

  void _initializeNextEditorController() {
    //Initialize the next video controller before assigning it to the main video editor controller
    if (currentVideoIndex + 1 < mediaFiles.value.length &&
        _nextVideoEditorController == null) {
      log('Calling the _initializeNextEditorController to intialized the next editor controller,..........');
      final nextVideoIndex = currentVideoIndex + 1;
      _nextVideoEditorController = VideoEditorController.file(
        mediaFiles.value[nextVideoIndex].file,
        minDuration: const Duration(seconds: 1),
        maxDuration: const Duration(seconds: 3600),
      );
      _nextVideoEditorController!.initialize().then((_) {
        _nextVideoEditorController!.video.addListener(_videoEditorListener);
        _nextVideoEditorController!.video.setLooping(false);
      }).catchError((error) {
        log('Error initializing next video controller: $error');
      });
    } else {
      log('The nextEditorController has been initialized at the first time in _initializeNextEditorController');
    }
  }

  void _playNextVideoController() {
    //If the _nextVideoEditorController is not equal to null, we will assign the reference to the main video editor contorller
    if (_nextVideoEditorController != null) {
      currentVideoIndex++;
      videoEditorController.value = _nextVideoEditorController!;
      videoEditorController.value.video.play();
      _nextVideoEditorController = null;
      setState(() {});
    }
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
        mediaFiles.value[currentMediaIndex].file,
        minDuration: const Duration(seconds: 1),
        maxDuration: const Duration(seconds: 3600),
      );
      _nextVideoEditorController!.initialize().then((_) {
        setState(() {
          //Create an instance that holds the reference to the previous video editor controller
          final previousVideoEditorController = videoEditorController.value;
          videoEditorController.value.video
              .removeListener(_videoEditorListener);
          videoEditorController.value = _nextVideoEditorController!;
          videoEditorController.value.video.addListener(_videoEditorListener);
          videoEditorController.value.video.setLooping(false);
          //Set the video position after the video is initialized, when the user has scrolled to the second video at the first time
          /*
          When a user adds two videos to the application, the timeline creates two media instances for each video. 
          If the user is viewing the first video and scrolls to the area of the second video in a single scroll action, 
          after stopping the scroll, the thumbnail of the video will jump to a position calculated based on the current media's scroll position.
          However, once the user scrolls to a specific position and 
          the video thumbnail above also seeks to the duration corresponding to the current offset,
           the video always starts from duration zero of the current media, 
           even though the user has scrolled to a position in the video that is not at the 0-second mark. 
           On the other hand, if the user scrolls past the second video for the first time without pressing play, 
           and then scrolls a bit further, the video starts from the current duration of the video.
          This issue is related to the controller transition. When the user has just scrolled past the second video, 
          the controller is in the process of being initialized, and the position is set before the controller is fully initialized. 
          This results in the video jumping back to the 0-second mark when play is pressed.
          
          */
          final newVideoPosition = mediaFiles.value[currentMediaIndex]
              .calculateCurrentPosition(_editorScrollController.offset)
              .toInt();
          videoEditorController.value.video
              .seekTo(Duration(milliseconds: newVideoPosition));
          //Release the memory of the previous controller after reassigning it
          previousVideoEditorController.dispose();
          _nextVideoEditorController =
              null; //remove reference to the new controller
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

  // void _playNextVideo() async {
  //   //Increase the currentVideoIndex that show the next video in the file list
  //   //Initializing the nextEditorController
  //   if (_nextVideoEditorController == null) {
  //     //When the video is reach end, jump to the last offset of the video
  //     // final currentMedia = mediaFiles[currentVideoIndex];
  //     // _updateCurrentScrollOffsetByMilisecond(currentMedia.durationInMilisecond);
  //     // log('The last offset is $currentScrollOffset');
  //     //If the index is valid and the list contains the file at index, try to
  //     //initialize it
  //     if (currentVideoIndex + 1 < _filesNotifier.value.length) {
  //       currentVideoIndex++;
  //       //Assign the last offset that the video has scrolled to
  //       currentScrollOffset = _editorScrollController.offset;
  //       log('currentScrollOffset --->: $currentScrollOffset');
  //       final nextFile = _filesNotifier.value[currentVideoIndex];
  //       log('Next file path: ${_filesNotifier.value[currentVideoIndex].path}');
  //       _nextVideoEditorController = VideoEditorController.file(
  //         nextFile,
  //         minDuration: const Duration(seconds: 1),
  //         maxDuration: const Duration(seconds: 3600),
  //       );
  //       _nextVideoEditorController!.initialize().then((_) {
  //         setState(() {
  //           _isPlayingVideo.value = true;
  //           videoEditorController.value.video
  //               .removeListener(_videoEditorListener);
  //           videoEditorController.value = _nextVideoEditorController!;
  //           videoEditorController.value.video.addListener(_videoEditorListener);
  //           videoEditorController.value.video.setLooping(false);
  //           videoEditorController.value.video.play();
  //           _nextVideoEditorController = null;
  //           log('next video is playing');
  //         });
  //       }).catchError((error, stacktrace) {
  //         log('Error in nextEditorController: $error');
  //         log('Stacktrace in _playNextVideo method: $stacktrace');
  //       });
  //     }
  //   } else {
  //     //Print out the message indicate the controller has been initilized
  //     log('The nextEditorController has been initialized');
  //   }
  // }

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

  // void _updateCurrentScrollOffset(int videoPositionInSecond) {
  //   log('videoPositionInSecond: $videoPositionInSecond');
  //   _editorScrollController.jumpTo(videoPositionInSecond * 60);
  //   // _editorScrollController.jumpTo(
  //   //   videoPositionInSecond / 60 * 1000,
  //   // );
  // }

  void _updateCurrentScrollOffsetByMilisecond(int videoPositionInMilisecond) {
    // final offset = currentScrollOffset + (videoPositionInMilisecond / 100) * 6;
    final curentMedia = mediaFiles.value[currentVideoIndex];
    final currentStartOffset = curentMedia.startOffset;
    /**
     * Explain for this formula below. As normally, 1000 milisecond is equal to 60 offset.
     * So each 100 milisecond will take 6 offset. Because I have created each Media instance for
     * each video that import to the timeline. Each Media will contain file, totalOffset, startOffset, endOffset
     * and durationInMilisecond. In the Media class, I have created the method for calculating the
     * currentPosition in milisecond based on the currentOffset in scrollView. Because the startOffset
     * of each media instance is different. If I want to know the current position in the video duration, 
     * I need to simplify the value. For example, if the currentOffset is belong to a media range
     * so I can know the startOffset and the endOffset of this media in the totalOffset of the entire the medias.
     * If I have a media start at 360 offset and end at 600 offset, and I have scrolled to 
     * 420 offset. At this time, we can imagine that 360 offset is 0 milisecond and 600 offset is 4000 ms
     * if I add 60 to 360 offset, I have 420 offset and it is equal to 2000 ms. So I have the fomula
     * likethis ((420 - startOffset) x 1000)) / 60 = milisecond. Based on this formula,
     * I can get the specific offset by refactoring above formula.
     *      */
    final offset =
        ((6 * videoPositionInMilisecond) + (100 * currentStartOffset)) / 100;
    _editorScrollController.jumpTo(offset);
    log('Offset in _updateCurrentScrollOffsetByMilisecond: $offset');
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
                  valueListenable: mediaFiles,
                  builder: (context, fileList, child) {
                    return Row(
                      children: List<Widget>.generate(fileList.length, (index) {
                        return fileList[index].fileType == MediaType.video
                            ? VideoFrame(file: fileList[index].file)
                            : ResizableImageFrame(imageMedia: fileList[index]);
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
                          ValueListenableBuilder(
                              valueListenable: _isPlayingVideo,
                              builder: (context, isPlaying, child) {
                                return Container(
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    onPressed: () {
                                      //Pause or play the video
                                      _isPlayingVideo.value =
                                          !_isPlayingVideo.value;
                                      //Allow the VideoPlayerController play the video
                                      if (_isPlayingVideo.value) {
                                        videoEditorController.value.video
                                            .play();
                                      } else {
                                        videoEditorController.value.video
                                            .pause();
                                      }
                                    },
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }),
                          Expanded(
                            child: Stack(
                              children: [
                                //Showing the video timeline preview, autio timeline, Text timeline
                                FractionallySizedBox(
                                  widthFactor: 0.94,
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
                                            // widget.videos.add(file);
                                            // _filesNotifier.value = [
                                            //   ..._filesNotifier.value,
                                            //   file
                                            // ];
                                            //Test check the file extension
                                            final mediaType =
                                                getMediaType(file.path);
                                            log(mediaType.toString());
                                            //Handle the case when the selected file is an image
                                            if (mediaType == MediaType.image) {
                                              Media media = Media(
                                                file: file,
                                                durationInMilisecond: 1000,
                                                fileType: mediaType,
                                              );
                                              //Adding the image media to the list
                                              widget.videos.add(media);
                                              // _filesNotifier.value = [
                                              //   ..._filesNotifier.value,
                                              //   media
                                              // ];
                                              //Add it to the mediaList
                                              mediaFiles.value = [
                                                ...mediaFiles.value,
                                                media
                                              ];
                                              //Reassign the totalOffset, start and end offset
                                              calculateStartAndEndOffsetForEachMedia(
                                                  mediaFiles.value);
                                              return;
                                            }

                                            //Get the duration in milisecond of the video
                                            final durationInMilisecond =
                                                await getVideoDurationInMilisecond(
                                                    file.path);
                                            //Creating new media file for the new imported video
                                            Media media = Media(
                                              file: file,
                                              durationInMilisecond:
                                                  durationInMilisecond,
                                              fileType: mediaType,
                                            );
                                            //Add it to the mediaList
                                            mediaFiles.value = [
                                              ...mediaFiles.value,
                                              media
                                            ];
                                            //Reassign the totalOffset, start and end offset
                                            calculateStartAndEndOffsetForEachMedia(
                                                mediaFiles.value);
                                            log('New video length list: ${widget.videos.length}');
                                            //Adding the video file to the list
                                            widget.videos.add(media);
                                            // _filesNotifier.value = [
                                            //   ..._filesNotifier.value,
                                            //   media
                                            // ];
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
                                          log('Image media: ${mediaFiles.value[1]}');
                                          // _buildAddTextDialog(context);
                                        },
                                      ),
                                      //The button for adding the audio
                                      ActionButton(
                                        svgIconPath:
                                            'assets/icons/music_note_icon.svg',
                                        onPressed: () {
                                          log('Showing the dialog for adding audio');
                                          if (mediaFiles.value.length > 1) {
                                            log('The first video information is: ${mediaFiles.value[0].toString()}');
                                            log('Next video information is: ${mediaFiles.value[1].toString()}');
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
