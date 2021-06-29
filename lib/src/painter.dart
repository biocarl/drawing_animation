import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'debug.dart';
import 'parser.dart';
import 'path_order.dart';
import 'types.dart';

/// Paints a list of [PathSegment] to canvas
class PaintedPainter extends PathPainter {
  PaintedPainter(
      Animation<double> animation,
      List<PathSegment> pathSegments,
      Size? customDimensions,
      List<Paint> paints,
      PaintedSegmentCallback? onFinishCallback,
      bool scaleToViewport,
      DebugOptions debugOptions)
      : super(animation, pathSegments, customDimensions, paints,
            onFinishCallback, scaleToViewport, debugOptions);

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);
    if (canPaint) {
      //pathSegments for AllAtOncePainter are always in the order of PathOrders.original
      pathSegments!.forEach((segment) {
        var paint = (paints.isNotEmpty)
            ? paints[segment.pathIndex]
            : (Paint()
              ..color = segment.color
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.square
              ..strokeWidth = segment.strokeWidth);
        canvas.drawPath(segment.path, paint);
      });

      //No callback etc. needed
      // super.onFinish(canvas, size);
    }
  }
}

/// Paints a list of [PathSegment] all-at-once to a canvas
class AllAtOncePainter extends PathPainter {
  AllAtOncePainter(
      Animation<double> animation,
      List<PathSegment> pathSegments,
      Size? customDimensions,
      List<Paint> paints,
      PaintedSegmentCallback? onFinishCallback,
      bool scaleToViewport,
      DebugOptions debugOptions)
      : super(animation, pathSegments, customDimensions, paints,
            onFinishCallback, scaleToViewport, debugOptions);

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);
    if (canPaint) {
      //pathSegments for AllAtOncePainter are always in the order of PathOrders.original
      pathSegments!.forEach((segment) {
        var subPath = segment.path
            .computeMetrics()
            .first
            .extractPath(0, segment.length * animation.value);

        var paint = (paints.isNotEmpty)
            ? paints[segment.pathIndex]
            : (Paint()
              ..color = segment.color
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.square
              ..strokeWidth = segment.strokeWidth);
        canvas.drawPath(subPath, paint);
      });

      super.onFinish(canvas, size);
    }
  }
}

/// Paints a list of [PathSegment] one-by-one to a canvas
class OneByOnePainter extends PathPainter {
  OneByOnePainter(
      Animation<double> animation,
      List<PathSegment> pathSegments,
      Size? customDimensions,
      List<Paint> paints,
      PaintedSegmentCallback? onFinishCallback,
      bool scaleToViewport,
      DebugOptions debugOptions)
      : totalPathSum = 0,
        super(animation, pathSegments, customDimensions, paints,
            onFinishCallback, scaleToViewport, debugOptions) {
    if (this.pathSegments != null) {
      this.pathSegments!.forEach((e) => totalPathSum += e.length);
    }
  }

  /// The total length of all summed up [PathSegment] elements of the parsed Svg
  double totalPathSum;

  /// The index of the last fully painted segment
  int paintedSegmentIndex = 0;

  /// The total painted path length - the length of the last partially painted segment
  double _paintedLength = 0.0;

  /// Path segments which will be painted to canvas at current frame
  List<PathSegment> toPaint = <PathSegment>[];

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);

    if (canPaint) {
      //[1] Calculate and search for upperBound of total path length which should be painted
      var upperBound = animation.value * totalPathSum;
      var currentIndex = paintedSegmentIndex;
      var currentLength = _paintedLength;
      while (currentIndex < pathSegments!.length - 1) {
        if (currentLength + pathSegments![currentIndex].length < upperBound) {
          toPaint.add(pathSegments![currentIndex]);
          currentLength += pathSegments![currentIndex].length;
          currentIndex++;
        } else {
          break;
        }
      }
      //[2] Extract subPath of last path which breaks the upperBound
      var subPathLength = upperBound - currentLength;
      var lastPathSegment = pathSegments![currentIndex];

      var subPath = lastPathSegment.path
          .computeMetrics()
          .first
          .extractPath(0, subPathLength);
      paintedSegmentIndex = currentIndex;
      _paintedLength = currentLength;
      // //[3] Paint all selected paths to canvas
      Paint paint;
      late Path tmp;
      if (animation.value == 1.0) {
        //hotfix: to ensure callback for last segment TODO not pretty
        toPaint.clear();
        toPaint.addAll(pathSegments!);
      } else {
        //[3.1] Add last subPath temporarily
        tmp = Path.from(lastPathSegment.path);
        lastPathSegment.path = subPath;
        toPaint.add(lastPathSegment);
      }
      //[3.2] Restore rendering order - last path element in original PathOrder should be last painted -> most visible
      //[3.3] Paint elements
      (toPaint..sort(Extractor.getComparator(PathOrders.original)))
          .forEach((segment) {
        paint = (paints.isNotEmpty)
            ? paints[segment.pathIndex]
            : (Paint() //Paint per path TODO implement Paint per PathSegment?
              //TODO Debug disappearing first lineSegment
              // ..color = (segment.relativeIndex == 0 && segment.pathIndex== 0) ? Colors.red : ((segment.relativeIndex == 1) ? Colors.blue : segment.color)
              ..color = segment.color
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.square
              ..strokeWidth = segment.strokeWidth);
        canvas.drawPath(segment.path, paint);
      });

      if (animation.value != 1.0) {
        //[3.4] Remove last subPath
        toPaint.remove(lastPathSegment);
        lastPathSegment.path = tmp;
      }

      //TODO Problem: Path drawning is a continous iteration over the length of all segments. To make a callback which fires exactly when path is drawn is therefore not possible (I can only ensure one of the two cases: 1) segment is completely drawn 2) no next segment was started to be drawn yet - For now: 1)
      // double remainingLength = lastPathSegment.length - subPathLength;

      super.onFinish(canvas, size, lastPainted: toPaint.length - 1);
    } else {
      paintedSegmentIndex = 0;
      _paintedLength = 0.0;
      toPaint.clear();
    }
  }
}

/// Abstract implementation of painting a list of [PathSegment] elements to a canvas
abstract class PathPainter extends CustomPainter {
  PathPainter(
      this.animation,
      this.pathSegments,
      this.customDimensions,
      this.paints,
      this.onFinishCallback,
      this.scaleToViewport,
      this.debugOptions)
      : canPaint = false,
        super(repaint: animation) {
    calculateBoundingBox();
  }

  /// Total bounding box of all paths
  Rect? pathBoundingBox;

  /// For expanding the bounding box when big stroke would breaks the bb
  double? strokeWidth;

  /// User defined dimensions for canvas
  Size? customDimensions;
  final Animation<double> animation;

  /// Each [PathSegment] represents a continuous Path element of the parsed Svg
  List<PathSegment>? pathSegments;

  /// Substitutes the paint object for each [PathSegment]
  List<Paint> paints;

  /// Status of animation
  bool canPaint;

  bool scaleToViewport;

  /// Evoked when frame is painted
  PaintedSegmentCallback? onFinishCallback;

  //For debug - show widget and svg bounding box and record canvas to *.png
  DebugOptions debugOptions;
  late ui.PictureRecorder recorder;

  // Get boundingBox by combining boundingBox of each PathSegment and inflating the resulting bounding box by half of the found max strokeWidth TODO find a better solution. This does only work if the stroke with maxWidth defines on side of bounding box. Otherwise it results to unwanted padding.
  void calculateBoundingBox() {
    var bb = pathSegments!.first.path.getBounds();
    var strokeWidth = 0;

    pathSegments!.forEach((e) {
      bb = bb.expandToInclude(e.path.getBounds());
      if (strokeWidth < e.strokeWidth) {
        strokeWidth = e.strokeWidth.toInt();
      }
    });

    if (paints.isNotEmpty) {
      paints.forEach((e) {
        if (strokeWidth < e.strokeWidth) {
          strokeWidth = e.strokeWidth.toInt();
        }
      });
    }
    pathBoundingBox = bb.inflate(strokeWidth / 2);
    this.strokeWidth = strokeWidth.toDouble();
  }

  void onFinish(Canvas canvas, Size size, {int lastPainted = -1}) {
    //-1: no segment was painted yet, 0 first segment
    if (debugOptions.recordFrames) {
      final  picture = recorder.endRecording();
      var frame = getFrameCount(debugOptions);
      if (frame >= 0) {
        print('Write frame $frame');
        //pass size when you want the whole viewport of the widget
        writeToFile(
            picture,
            '${debugOptions.outPutDir}/${debugOptions.fileName}_$frame.png',
            size);
      }
    }
    onFinishCallback!(lastPainted);
  }

  Canvas paintOrDebug(Canvas canvas, Size size) {
    if (debugOptions.recordFrames) {
      recorder = ui.PictureRecorder();
      canvas = Canvas(recorder);
      //Color background
      // canvas.drawColor(Color.fromRGBO(224, 121, 42, 1.0),BlendMode.srcOver);
      //factor for higher resolution
      canvas.scale(debugOptions.resolutionFactor,
          debugOptions.resolutionFactor);
    }
    paintPrepare(canvas, size);
    return canvas;
  }

  void paintPrepare(Canvas canvas, Size size) {
    canPaint = animation.status == AnimationStatus.forward ||
        animation.status == AnimationStatus.completed;

    if (canPaint) viewBoxToCanvas(canvas, size);
  }

  Future<void> writeToFile(
      ui.Picture picture, String fileName, Size size) async {
    var scale = calculateScaleFactor(size);
    var byteData = await ((await picture.toImage(
            (scale.x *
                    debugOptions.resolutionFactor *
                    pathBoundingBox!.width)
                .round(),
            (scale.y *
                    debugOptions.resolutionFactor *
                    pathBoundingBox!.height)
                .round()))
        .toByteData(format: ui.ImageByteFormat.png));
    final buffer = byteData!.buffer;
    await File(fileName).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    print('File: $fileName written.');
  }

  _ScaleFactor calculateScaleFactor(Size viewBox) {
    //Scale factors
    var dx = (viewBox.width) / pathBoundingBox!.width;
    var dy = (viewBox.height) / pathBoundingBox!.height;

    //Applied scale factors
    late double ddx, ddy;

    //No viewport available
    assert(!(dx == 0 && dy == 0));

    //Case 1: Both width/height is specified or MediaQuery
    if (!viewBox.isEmpty) {
      if (customDimensions != null) {
        //Custom width/height
        ddx = dx;
        ddy = dy;
      } else {
        ddx = ddy = min(dx, dy); //Maintain resolution and viewport
      }
      //Case 2: CustomDimensions specifying only one side
    } else if (dx == 0) {
      ddx = ddy = dy;
    } else if (dy == 0) {
      ddx = ddy = dx;
    }
    return _ScaleFactor(ddx, ddy);
  }

  void viewBoxToCanvas(Canvas canvas, Size size) {
    if (debugOptions.showViewPort) {
      var clipRect1 = Offset.zero & size;
      var ppp = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.green
        ..strokeWidth = 10.50;
      canvas.drawRect(clipRect1, ppp);
    }

    if (scaleToViewport) {
      //Viewbox with Offset.zero
      var viewBox = (customDimensions != null)
          ? customDimensions
          : Size.copy(size);
      var scale = calculateScaleFactor(viewBox!);
      canvas.scale(scale.x, scale.y);

      //If offset
      var offset = Offset.zero - pathBoundingBox!.topLeft;
      canvas.translate(offset.dx, offset.dy);

      //Center offset - TODO should this be a option flag?
      if (debugOptions.recordFrames != true) {
        var center = Offset(
            (size.width / scale.x - pathBoundingBox!.width) / 2,
            (size.height / scale.y - pathBoundingBox!.height) / 2);
        canvas.translate(center.dx, center.dy);
      }
    }

    //Clip bounds
    var clipRect = pathBoundingBox;
    if (!(debugOptions.showBoundingBox || debugOptions.showViewPort)) {
      canvas.clipRect(clipRect!);
    }

    if (debugOptions.showBoundingBox) {
      var pp = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.red
        ..strokeWidth = 0.500;
      canvas.drawRect(clipRect!, pp);
    }
  }

  @override
  bool shouldRepaint(PathPainter old) => true;
}

class _ScaleFactor {
  const _ScaleFactor(this.x, this.y);
  final double x;
  final double y;
}
