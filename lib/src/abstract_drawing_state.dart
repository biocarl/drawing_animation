import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'drawing_widget.dart';
import 'debug.dart';
import 'line_animation.dart';
import 'painter.dart';
import 'parser.dart';
import 'path_painter_builder.dart';
import 'range.dart';
import 'path_order.dart';

/// Base class for _AnimatedDrawingState and _AnimatedDrawingWithTickerState
abstract class AbstractAnimatedDrawingState extends State<AnimatedDrawing> {
  AbstractAnimatedDrawingState() {
    onFinishAnimation = onFinishAnimationDefault;
  }

  AnimationController? controller;
  CurvedAnimation? curve;
  Curve? animationCurve;
  AnimationRange? range;
  String? assetPath;
  PathOrder? animationOrder;
  DebugOptions? debug;
  int lastPaintedPathIndex = -1;

  List<PathSegment> pathSegments = <PathSegment>[];
  List<PathSegment> pathSegmentsToAnimate =
      <PathSegment>[]; //defined by [range.start] and [range.end]
  List<PathSegment> pathSegmentsToPaintAsBackground =
      <PathSegment>[]; //defined by < [range.start]

  VoidCallback? onFinishAnimation;

  /// Ensure that callback fires off only once even widget is rebuild.
  bool onFinishEvoked = false;

  void onFinishAnimationDefault() {
    if (widget.onFinish != null) {
      widget.onFinish!();
      if (debug!.recordFrames) resetFrame(debug);
    }
  }

  void onFinishFrame(int currentPaintedPathIndex) {
    if (newPathPainted(currentPaintedPathIndex)) {
      evokeOnPaintForNewlyPaintedPaths(currentPaintedPathIndex);
    }
    if (controller!.status == AnimationStatus.completed) {
      onFinishAnimation!();
    }
  }

  void evokeOnPaintForNewlyPaintedPaths(int currentPaintedPathIndex) {
    final paintedPaths = pathSegments[currentPaintedPathIndex].pathIndex -
        lastPaintedPathIndex; //TODO you should iterate over the indices of the sorted path segments not the original ones
    for (var i = lastPaintedPathIndex + 1;
        i <= lastPaintedPathIndex + paintedPaths;
        i++) {
      evokeOnPaintForPath(i);
    }
    lastPaintedPathIndex = currentPaintedPathIndex;
  }

  void evokeOnPaintForPath(int i) {
    //Only evoked in next frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        widget.onPaint!(i, widget.paths[i]);
      });
    });
  }

  bool newPathPainted(int currentPaintedPathIndex) {
    return widget.onPaint != null &&
        currentPaintedPathIndex != -1 &&
        pathSegments[currentPaintedPathIndex].pathIndex - lastPaintedPathIndex >
            0;
  }

  @override
  void didUpdateWidget(AnimatedDrawing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (animationOrder != widget.animationOrder) {
      applyPathOrder();
    }
  }

  @override
  void initState() {
    super.initState();
    updatePathData();
    applyAnimationCurve();
    applyDebugOptions();
  }

  void applyDebugOptions() {
    //If DebugOptions changes a hot restart is needed.
    debug = widget.debug;
    debug ??= DebugOptions();
  }

  void applyAnimationCurve() {
    if (controller != null && widget.animationCurve != null) {
      curve =
          CurvedAnimation(parent: controller!, curve: widget.animationCurve!);
      animationCurve = widget.animationCurve;
    }
  }

  //TODO Refactor
  Animation<double> getAnimation() {
    Animation<double> animation;
    if (widget.run == null || widget.run! == false) {
      animation = controller!;
    } else if (curve != null && animationCurve == widget.animationCurve) {
      animation = curve!;
    } else if (widget.animationCurve != null && controller != null) {
      curve =
          CurvedAnimation(parent: controller!, curve: widget.animationCurve!);
      animationCurve = widget.animationCurve;
      animation = curve!;
    } else {
      animation = controller!;
    }
    return animation;
  }

  void applyPathOrder() {
    if (pathSegments.isEmpty) return;

    setState(() {
      if (checkIfDefaultOrderSortingRequired()) {
        pathSegments.sort(Extractor.getComparator(PathOrders.original));
        animationOrder = PathOrders.original;
        return;
      }

      if (widget.animationOrder != animationOrder) {
        pathSegments.sort(Extractor.getComparator(widget.animationOrder));
        animationOrder = widget.animationOrder;
      }
    });
  }

  PathPainter? buildForegroundPainter() {
    if (pathSegmentsToAnimate.isEmpty) return null;
    var builder = preparePathPainterBuilder(widget.lineAnimation);
    builder.setPathSegments(pathSegmentsToAnimate);
    return builder.build();
  }

  PathPainter? buildBackgroundPainter() {
    if (pathSegmentsToPaintAsBackground.isEmpty) return null;
    var builder = preparePathPainterBuilder();
    builder.setPathSegments(pathSegmentsToPaintAsBackground);
    return builder.build();
  }

  PathPainterBuilder preparePathPainterBuilder([LineAnimation? lineAnimation]) {
    var builder = PathPainterBuilder(lineAnimation);
    builder.setAnimation(getAnimation());
    builder.setCustomDimensions(getCustomDimensions());
    builder.setPaints(widget.paints);
    builder.setOnFinishFrame(onFinishFrame);
    builder.setScaleToViewport(widget.scaleToViewport);
    builder.setDebugOptions(debug!);
    return builder;
  }

  //TODO refactor to be range not null
  void assignPathSegmentsToPainters() {
    if (pathSegments.isEmpty) return;

    if (widget.range == null) {
      pathSegmentsToAnimate = pathSegments;
      range = null;
      pathSegmentsToPaintAsBackground.clear();
      return;
    }

    if (widget.range != range) {
      checkValidRange();

      pathSegmentsToPaintAsBackground = pathSegments
          .where((x) => x.pathIndex < widget.range!.start!)
          .toList();

      pathSegmentsToAnimate = pathSegments
          .where((x) => (x.pathIndex >= widget.range!.start! &&
              x.pathIndex <= widget.range!.end!))
          .toList();

      range = widget.range;
    }
  }

  void checkValidRange() {
    RangeError.checkValidRange(
        widget.range!.start!,
        widget.range!.end,
        widget.paths.length - 1,
        'start',
        'end',
        'The provided range is invalid for the provided number of paths.');
  }

  // TODO Refactor
  Size? getCustomDimensions() {
    if (widget.height != null || widget.width != null) {
      return Size(
        widget.width!,
        widget.height!,
      );
    } else {
      return null;
    }
  }

  CustomPaint createCustomPaint(BuildContext context) {
    updatePathData(); //TODO Refactor - SRP broken (see method name)
    return CustomPaint(
        foregroundPainter: buildForegroundPainter(),
        painter: buildBackgroundPainter(),
        size: Size.copy(MediaQuery.of(context).size));
  }

  // TODO Refactor
  void addListenersToAnimationController() {
    if (debug!.recordFrames) {
      controller!.view.addListener(() {
        setState(() {
          if (controller!.status == AnimationStatus.forward) {
            iterateFrame(debug!);
          }
        });
      });
    }

    controller!.view.addListener(() {
      setState(() {
        if (controller!.status == AnimationStatus.dismissed) {
          lastPaintedPathIndex = -1;
        }
      });
    });
  }

  void updatePathData() {
    parsePathData();
    applyPathOrder();
    assignPathSegmentsToPainters();
  }

  void parsePathData() {
    var parser = SvgParser();
    if (svgAssetProvided()) {
      if (widget.assetPath == assetPath) return;

      parseFromSvgAsset(parser);
    } else if (pathsProvided()) {
      parseFromPaths(parser);
    }
  }

  void parseFromPaths(SvgParser parser) {
    parser.loadFromPaths(widget
        .paths); //Path object are parsed completely upon every state change
    setState(() {
      pathSegments = parser.getPathSegments();
    });
  }

  bool pathsProvided() => widget.paths.isNotEmpty;

  bool svgAssetProvided() => widget.assetPath.isNotEmpty;

  void parseFromSvgAsset(SvgParser parser) {
    parser.loadFromFile(widget.assetPath).then((_) {
      setState(() {
        //raw paths
        widget.paths.clear();
        widget.paths.addAll(parser.getPaths());
        //corresponding segments
        pathSegments = parser.getPathSegments();
        assetPath = widget.assetPath;
      });
    });
  }

  bool checkIfDefaultOrderSortingRequired() {
    // always keep paths for allAtOnce animation in original path order so we do not sort for the correct PaintOrder later on (which is pretty expensive for AllAtOncePainter)
    final defaultSortingWhenNoOrderDefined =
        widget.lineAnimation == LineAnimation.allAtOnce &&
            animationOrder != PathOrders.original;
    return defaultSortingWhenNoOrderDefined || widget.lineAnimation == null;
  }
}
