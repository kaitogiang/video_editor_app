class Frame {
  final String imagePath; //The imagePath of the frame
  final int durationInMilisecond; //The duration of this frame
  final double width; //The width of this frame

  const Frame({required this.imagePath, required this.durationInMilisecond})
      : width = (durationInMilisecond * 60) / 1000;
  //1000 miliseconds <=> 60 offset
}
