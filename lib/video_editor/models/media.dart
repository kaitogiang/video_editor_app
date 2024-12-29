import 'dart:io';

class Media {
  //The file represent the media, video or image
  File file;
  //The total offset that the video or image will take up
  //1000 milisecond -> 60 offset, so the total offset will depend on durationInMilisecond
  double totalOffset;
  //The total duration of the video or image in milisecond unit.
  int durationInMilisecond;
  //The start position offset in the actual scrollview
  double startOffset;
  //The end position offset in the actual scrollview
  double endOffset;

  Media(
      {required this.file,
      this.totalOffset = 0.0,
      required this.durationInMilisecond,
      this.startOffset = 0,
      this.endOffset = 0});

  //The method calculate the current video position in milisecond
  //The method will return the milisecond position of the video
  double calculateCurrentPosition(double currentOffset) {
    //The above formula is depended on the basic calculation for only one video
    //The basic formala is like this:
    //milisecond = (currentOffset * 1000 milisecond) / 60 offset
    //Based on this formula, we need to minus for startOffset because if the video is not
    //the first video, so the startOffset wont's start by 0. I minus for startOffset because
    //I want to convert the currentOffset to zero. So it will start from 0 to totalOffset
    //It looks like very confused, but let's give a simple example
    //I have two video, the first video is 6000 milisecond, the second video is 4000 milisecond
    //So let's calculate the totalOffset, start and end offset
    //For the first video, total offset is 360
    return ((currentOffset - startOffset) * 1000) / 60;
  }

  //This method will check whether the current offset is belong to this media.
  //if the current offset is >= startOffset and < endOffset, so it's belong to this media.
  //then return true;
  bool checkCurrentOffsetIsInMediaRange(double currentOffset) {
    return currentOffset >= startOffset && currentOffset < endOffset;
  }

  @override
  String toString() {
    return 'Milisecond: $durationInMilisecond, totalOffset: $totalOffset, startOffset: $startOffset, endOffset: $endOffset';
  }
}
