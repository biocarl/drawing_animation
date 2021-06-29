/// If recordFrame is true, the canvas of the AnimatedWidget remains white while writing each frame to the file [outPutDir]/[fileName]_[frame].png.
///
/// This method is not deterministic in several ways: 1) The final resolution depends on the resolution of the device 2) The total amount of frames gathered can also be different. This feature is intended to be used for creating decent looking Gifs which also look good on larger screen resolutions like desktop computers. Do not use this in production.
class DebugOptions {
  DebugOptions({
    this.showBoundingBox = false,
    this.showViewPort = false,
    this.recordFrames = false,
    this.resolutionFactor = 1.0,
    this.fileName = '',
    this.outPutDir = '',
  });

  final bool showBoundingBox;
  final bool showViewPort;
  final bool recordFrames;
  final String outPutDir;
  final String fileName;

  /// The final resultion is obtained by multiplying [resolutionFactor] with the resolution of the device.
  final double resolutionFactor;

  /// Keeping track of new frames
  int _frameCount = -1;
}

void resetFrame(DebugOptions? options) {
  options!._frameCount = -1;
}

void iterateFrame(DebugOptions options) {
  options._frameCount++;
}

int getFrameCount(DebugOptions options) {
  return options._frameCount;
}
