import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui';
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
    this.onFinishAnimation = onFinishAnimationDefault;
  }

  AnimationController controller;
  CurvedAnimation curve;
  Curve animationCurve;
  AnimationRange range;
  String assetPath;
  PathOrder animationOrder;
  DebugOptions debug;
  int lastPaintedPathIndex = -1;

  List<PathSegment> pathSegments = List<PathSegment>();
  List<PathSegment> pathSegmentsToAnimate =
      List<PathSegment>(); //defined by [range.start] and [range.end]
  List<PathSegment> pathSegmentsToPaintAsBackground =
      List<PathSegment>(); //defined by < [range.start]

  VoidCallback onFinishAnimation;

  /// Ensure that callback fires off only once even widget is rebuild.
  bool onFinishEvoked = false;

  void onFinishAnimationDefault() {
    if (this.widget.onFinish != null) {
      this.widget.onFinish();
      if (debug.recordFrames) resetFrame(debug);
    }
  }

  void onFinishFrame(int currentPaintedPathIndex) {
    if (newPathPainted(currentPaintedPathIndex)) {
      evokeOnPaintForNewlyPaintedPaths(currentPaintedPathIndex);
    }
    if (this.controller.status == AnimationStatus.completed) {
      this.onFinishAnimation();
    }
  }

  void evokeOnPaintForNewlyPaintedPaths(int currentPaintedPathIndex) {
    final int paintedPaths = pathSegments[currentPaintedPathIndex].pathIndex -
        lastPaintedPathIndex; //TODO you should iterate over the indices of the sorted path segments not the original ones
    for (int i = lastPaintedPathIndex + 1;
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
        this.widget.onPaint(i, this.widget.paths[i]);
      });
    });
  }

  bool newPathPainted(int currentPaintedPathIndex) {
    return this.widget.onPaint != null &&
        currentPaintedPathIndex != -1 &&
        pathSegments[currentPaintedPathIndex].pathIndex - lastPaintedPathIndex >
            0;
  }

  @override
  void didUpdateWidget(AnimatedDrawing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (this.animationOrder != this.widget.animationOrder) {
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
    this.debug = this.widget.debug;
    this.debug ??= DebugOptions();
  }

  void applyAnimationCurve() {
    if (this.controller != null && widget.animationCurve != null) {
      this.curve = CurvedAnimation(
          parent: this.controller, curve: this.widget.animationCurve);
      this.animationCurve = widget.animationCurve;
    }
  }

  //TODO Refactor
  Animation<double> getAnimation() {
    Animation<double> animation;
    if (this.widget.run == null || !this.widget.run) {
      animation = this.controller;
    } else if (this.curve != null &&
        this.animationCurve == widget.animationCurve) {
      animation = this.curve;
    } else if (widget.animationCurve != null && this.controller != null) {
      this.curve = CurvedAnimation(
          parent: this.controller, curve: widget.animationCurve);
      this.animationCurve = widget.animationCurve;
      animation = this.curve;
    } else {
      animation = this.controller;
    }
    return animation;
  }

  void applyPathOrder() {
    if (this.pathSegments.isEmpty) return;

    setState(() {
      if (checkIfDefaultOrderSortingRequired()) {
        this.pathSegments.sort(Extractor.getComparator(PathOrders.original));
        this.animationOrder = PathOrders.original;
        return;
      }

      if (this.widget.animationOrder != this.animationOrder) {
        this
            .pathSegments
            .sort(Extractor.getComparator(this.widget.animationOrder));
        this.animationOrder = this.widget.animationOrder;
      }
    });
  }

  PathPainter buildForegroundPainter() {
    if (pathSegmentsToAnimate.isEmpty) return null;
    PathPainterBuilder builder =
        preparePathPainterBuilder(this.widget.lineAnimation);
    builder.setPathSegments(this.pathSegmentsToAnimate);
    return builder.build();
  }

  PathPainter buildBackgroundPainter() {
    if (pathSegmentsToPaintAsBackground.isEmpty) return null;
    PathPainterBuilder builder = preparePathPainterBuilder();
    builder.setPathSegments(this.pathSegmentsToPaintAsBackground);
    return builder.build();
  }

  PathPainterBuilder preparePathPainterBuilder([LineAnimation lineAnimation]) {
    PathPainterBuilder builder = PathPainterBuilder(lineAnimation);
    builder.setAnimation(getAnimation());
    builder.setCustomDimensions(getCustomDimensions());
    builder.setPaints(this.widget.paints);
    builder.setOnFinishFrame(this.onFinishFrame);
    builder.setScaleToViewport(this.widget.scaleToViewport);
    builder.setDebugOptions(this.debug);
    return builder;
  }

  //TODO refactor to be range not null
  void assignPathSegmentsToPainters() {
    if (this.pathSegments.isEmpty) return;

    if (this.widget.range == null) {
      this.pathSegmentsToAnimate = this.pathSegments;
      this.range = null;
      this.pathSegmentsToPaintAsBackground.clear();
      return;
    }

    if (this.widget.range != this.range) {
      checkValidRange();

      this.pathSegmentsToPaintAsBackground = this
          .pathSegments
          .where((x) => x.pathIndex < this.widget.range.start)
          .toList();

      this.pathSegmentsToAnimate = this
          .pathSegments
          .where((x) => (x.pathIndex >= this.widget.range.start &&
              x.pathIndex <= this.widget.range.end))
          .toList();

      this.range = this.widget.range;
    }
  }

  void checkValidRange() {
    RangeError.checkValidRange(
        this.widget.range.start,
        this.widget.range.end,
        this.widget.paths.length - 1,
        "start",
        "end",
        "The provided range is invalid for the provided number of paths.");
  }

  // TODO Refactor
  Size getCustomDimensions() {
    if (widget.height != null || widget.width != null) {
      return Size(
        (widget.width != null) ? widget.width : 0,
        (widget.height != null) ? widget.height : 0,
      );
    } else {
      return null;
    }
  }

  CustomPaint createCustomPaint(BuildContext context) {
    updatePathData(); //TODO Refactor - SRP broken (see method name)
    return new CustomPaint(
        foregroundPainter: buildForegroundPainter(),
        painter: buildBackgroundPainter(),
        size: Size.copy(MediaQuery.of(context).size));
  }

  // TODO Refactor
  void addListenersToAnimationController() {
    if (this.debug.recordFrames) {
      this.controller.view.addListener(() {
        setState(() {
          if (this.controller.status == AnimationStatus.forward) {
            iterateFrame(debug);
          }
        });
      });
    }

    this.controller.view.addListener(() {
      setState(() {
        if (this.controller.status == AnimationStatus.dismissed) {
          this.lastPaintedPathIndex = -1;
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
    SvgParser parser = new SvgParser();
    if (svgAssetProvided()) {
      if(this.widget.assetPath == this.assetPath)
        return;

      parseFromSvgAsset(parser);
    } else if (pathsProvided()) {
      parseFromPaths(parser);
    }
  }

  void parseFromPaths(SvgParser parser) {
    parser.loadFromPaths(this
        .widget
        .paths); //Path object are parsed completely upon every state change
    setState(() {
      this.pathSegments = parser.getPathSegments();
    });
  }

  bool pathsProvided() => this.widget.paths.isNotEmpty;

  bool svgAssetProvided() => this.widget.assetPath.isNotEmpty;

  void parseFromSvgAsset(SvgParser parser) {
    parser.loadFromFile(this.widget.assetPath).then((_) {
      setState(() {
        //raw paths
        this.widget.paths.clear();
        this.widget.paths.addAll(parser.getPaths());
        //corresponding segments
        this.pathSegments = parser.getPathSegments();
        this.assetPath = this.widget.assetPath;
      });
    });
  }

  bool checkIfDefaultOrderSortingRequired() {
    // always keep paths for allAtOnce animation in original path order so we do not sort for the correct PaintOrder later on (which is pretty expensive for AllAtOncePainter)
    final bool defaultSortingWhenNoOrderDefined = this.widget.lineAnimation == LineAnimation.allAtOnce && this.animationOrder != PathOrders.original;
    return defaultSortingWhenNoOrderDefined || this.widget.lineAnimation == null;
  }
}
