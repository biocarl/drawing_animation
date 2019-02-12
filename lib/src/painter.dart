import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'debug.dart';
import 'parser.dart';
import 'path_order.dart';

/// Paints a list of [PathSegment] all-at-once to a canvas
class AllAtOncePainter extends PathPainter {
  AllAtOncePainter(
      Animation<double> animation,
      List<PathSegment> pathSegments,
      Size customDimensions,
      List<Paint> paints,
      VoidCallback onFinishCallback,
      DebugOptions debugOptions)
      : super(animation, pathSegments, customDimensions, paints,
            onFinishCallback, debugOptions);

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);
    if (canPaint) {
      (pathSegments
            ..sort(Extractor.getComparator(PathOrders
                .original))) //TODO only if different PathOrder was set, check
          .forEach((segment) {
        Path subPath = segment.path
            .computeMetrics()
            .first
            .extractPath(0, segment.length * this.animation.value);

        Paint paint = (this.paints.isNotEmpty)
            ? this.paints[segment.pathIndex]
            : (new Paint()
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
      Size customDimensions,
      List<Paint> paints,
      VoidCallback onFinishCallback,
      DebugOptions debugOptions)
      : this.totalPathSum = 0,
        super(animation, pathSegments, customDimensions, paints,
            onFinishCallback, debugOptions) {
    if (this.pathSegments != null) {
      this.pathSegments.forEach((e) => this.totalPathSum += e.length);
    }
  }

  /// The total length of all summed up [PathSegment] elements of the parsed Svg
  double totalPathSum;

  /// The index of the last fully painted segment
  int paintedSegmentIndex = 0;

  /// The total painted path length - the length of the last partially painted segment
  double _paintedLength = 0.0;

  /// Path segments which will be painted to canvas at current frame
  List<PathSegment> toPaint = new List();

  @override
  void paint(Canvas canvas, Size size) {
    canvas = super.paintOrDebug(canvas, size);

    if (canPaint) {
      //[1] Calculate and search for upperBound of total path length which should be painted
      double upperBound = this.animation.value * totalPathSum;
      int currentIndex = this.paintedSegmentIndex;
      double currentLength = this._paintedLength;
      while (currentIndex < pathSegments.length - 1) {
        if (currentLength + pathSegments[currentIndex].length < upperBound) {
          toPaint.add(pathSegments[currentIndex]);
          currentLength += pathSegments[currentIndex].length;
          currentIndex++;
        } else {
          break;
        }
      }
      //[2] Extract subPath of last path which breaks the upperBound
      double subPathLength = upperBound - currentLength;
      PathSegment lastPathSegment = pathSegments[currentIndex];
      Path subPath = lastPathSegment.path
          .computeMetrics()
          .first
          .extractPath(0, subPathLength);
      this.paintedSegmentIndex = currentIndex;
      this._paintedLength = currentLength;
      // //[3] Paint all selected paths to canvas
      Paint paint;
      //[3.1] Add last subPath temporarily
      Path tmp = Path.from(lastPathSegment.path);
      lastPathSegment.path = subPath;
      toPaint.add(lastPathSegment);
      //[3.2] Restore rendering order - last path element in original PathOrder should be last painted -> most visible
      //[3.3] Paint elements
      (toPaint..sort(Extractor.getComparator(PathOrders.original)))
          .forEach((segment) {
        paint = (this.paints.isNotEmpty)
            ? this.paints[segment.pathIndex]
            : (new Paint() //Paint per path TODO implement Paint per PathSegment?
              //TODO Debug disappearing first lineSegment
              // ..color = (segment.relativeIndex == 0 && segment.pathIndex== 0) ? Colors.red : ((segment.relativeIndex == 1) ? Colors.blue : segment.color)
              ..color = segment.color
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.square
              ..strokeWidth = segment.strokeWidth);
        canvas.drawPath(segment.path, paint);
      });
      //[3.4] Remove last subPath
      toPaint.remove(lastPathSegment);
      lastPathSegment.path = tmp;

      super.onFinish(canvas, size);
    } else {
      this.paintedSegmentIndex = 0;
      this._paintedLength = 0.0;
      this.toPaint.clear();
    }
  }
}

/// Abstract implementation of painting a list of [PathSegment] elements to a canvas
abstract class PathPainter extends CustomPainter {
  PathPainter(this.animation, this.pathSegments, this.customDimensions,
      this.paints, this.onFinishCallback, this.debugOptions)
      : frame = -1,
        canPaint = false,
        super(repaint: animation) {
    if (this.pathSegments != null) {
      calculateBoundingBox();
    }
  }

  /// Total bounding box of all paths
  Rect pathBoundingBox;

  /// For expanding the bounding box when big stroke would breaks the bb
  double strokeWidth;

  /// User defined dimensions for canvas
  Size customDimensions;
  final Animation<double> animation;

  /// Each [PathSegment] represents a continuous Path element of the parsed Svg
  List<PathSegment> pathSegments;

  /// Substitutes the paint object for each [PathSegment]
  List<Paint> paints;

  /// Number of painted frames
  int frame;

  /// Status of animation
  bool canPaint;

  /// Evoked when last path of animation is painted
  VoidCallback onFinishCallback;

  //For debug - show widget and svg bounding box and record canvas to *.png
  DebugOptions debugOptions;
  ui.PictureRecorder recorder;

  // Get boundingBox by combining boundingBox of each PathSegment and inflating the resulting bounding box by half of the found max strokeWidth TODO find a better solution. This does only work if the stroke with maxWidth defines on side of bounding box. Otherwise it results to unwanted padding.
  void calculateBoundingBox() {
    Rect bb = this.pathSegments.first.path.getBounds();
    double strokeWidth = 0;

    this.pathSegments.forEach((e) {
      bb = bb.expandToInclude(e.path.getBounds());
      if (strokeWidth < e.strokeWidth) {
        strokeWidth = e.strokeWidth;
      }
    });

    if (this.paints.isNotEmpty) {
      paints.forEach((e) {
        if (strokeWidth < e.strokeWidth) {
          strokeWidth = e.strokeWidth;
        }
      });
    }
    this.pathBoundingBox = bb.inflate(strokeWidth / 2);
    this.strokeWidth = strokeWidth;
  }

  void onFinish(Canvas canvas, Size size) {
    if (this.debugOptions.recordFrames) {
      final ui.Picture picture = recorder.endRecording();
      if (this.frame >= 0) {
        print("Write frame $frame");
        //pass size when you want the whole viewport of the widget
        writeToFile(
            picture,
            "${debugOptions.outPutDir}/${debugOptions.fileName}_${this.frame}.png",
            size);
      }
    }

    if (this.animation.status == AnimationStatus.completed) {
      this.onFinishCallback();
    }
  }

  Canvas paintOrDebug(Canvas canvas, Size size) {
    if (this.debugOptions.recordFrames) {
      recorder = ui.PictureRecorder();
      canvas = Canvas(recorder);
      //Color background
      // canvas.drawColor(Color.fromRGBO(224, 121, 42, 1.0),BlendMode.srcOver);
      //factor for higher resolution
      canvas.scale(this.debugOptions.resolutionFactor,
          this.debugOptions.resolutionFactor);
    }
    paintPrepare(canvas, size);
    return canvas;
  }

  void paintPrepare(Canvas canvas, Size size) {
    this.canPaint = this.animation.status == AnimationStatus.forward ||
        this.animation.status == AnimationStatus.completed;
    if (this.canPaint) {
      frame++;
      viewBoxToCanvas(canvas, size);
    } else {
      frame = -1;
    }
  }

  Future<void> writeToFile(
      ui.Picture picture, String fileName, Size size) async {
    _ScaleFactor scale = calculateScaleFactor(size);
    ByteData byteData = await ((await picture.toImage(
            (scale.x *
                    this.debugOptions.resolutionFactor *
                    this.pathBoundingBox.width)
                .round(),
            (scale.y *
                    this.debugOptions.resolutionFactor *
                    this.pathBoundingBox.height)
                .round()))
        .toByteData(format: ui.ImageByteFormat.png));
    final buffer = byteData.buffer;
    await File(fileName).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    print("File: $fileName written.");
  }

  _ScaleFactor calculateScaleFactor(Size viewBox) {
    //Scale factors
    double dx = (viewBox.width) / this.pathBoundingBox.width;
    double dy = (viewBox.height) / this.pathBoundingBox.height;

    //Applied scale factors
    double ddx, ddy;

    //No viewport available
    assert(!(dx == 0 && dy == 0));

    //Case 1: Both width/height is specified or MediaQuery
    if (!viewBox.isEmpty) {
      if (this.customDimensions != null) {
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
    if (this.debugOptions.showViewPort) {
      Rect clipRect1 = Offset.zero & size;
      Paint ppp = new Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.green
        ..strokeWidth = 10.50;
      canvas.drawRect(clipRect1, ppp);
    }

    //Viewbox with Offset.zero
    Size viewBox = (this.customDimensions != null)
        ? this.customDimensions
        : Size.copy(size);

    _ScaleFactor scale = calculateScaleFactor(viewBox);
    canvas.scale(scale.x, scale.y);

    //If offset
    Offset offset = Offset.zero - this.pathBoundingBox.topLeft;
    canvas.translate(offset.dx, offset.dy);

    //Center offset - TODO should this be a option flag?
    if (this.debugOptions.recordFrames != true) {
      Offset center = Offset(
          (size.width / scale.x - this.pathBoundingBox.width) / 2,
          (size.height / scale.y - this.pathBoundingBox.height) / 2);
      canvas.translate(center.dx, center.dy);
    }

    //Clip bounds
    Rect clipRect = this.pathBoundingBox;
    if (!(this.debugOptions.showBoundingBox || this.debugOptions.showViewPort))
      canvas.clipRect(clipRect);

    if (this.debugOptions.showBoundingBox) {
      Paint pp = new Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.red
        ..strokeWidth = 0.500;
      canvas.drawRect(clipRect, pp);
    }
  }

  @override
  bool shouldRepaint(PathPainter old) => true;
}

class _ScaleFactor {
  const _ScaleFactor(this.x, this.y);
  final x;
  final y;
}
