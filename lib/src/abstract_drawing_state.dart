import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui';
import 'drawing_widget.dart';
import 'debug.dart';
import 'line_animation.dart';
import 'painter.dart';
import 'parser.dart';
import 'range.dart';
import 'path_order.dart';
import 'types.dart';

/// Base class for _AnimatedDrawingState and _AnimatedDrawingWithTickerState
abstract class AbstractAnimatedDrawingState extends State<AnimatedDrawing> {
  AbstractAnimatedDrawingState() {
    //Set Callbacks
    this.onFinishAnimationDefault = () {
      if (this.widget.onFinish != null) {
        this.widget.onFinish();
        if (debug.recordFrames) resetFrame(debug);
      }
    };
    this.onFinishAnimation = onFinishAnimationDefault;

    //Called whenever a frame is drawn by the painter
    this.onFinishFrame = (index) {
      if (this.widget.onPaint != null && index != -1) {
        //before first segment (index == 0) is painted
        int paintedDiff = pathSegments[index].pathIndex - lastPaintedPathIndex;
        if (paintedDiff > 0) {
          for (int i = lastPaintedPathIndex + 1;
              i <= lastPaintedPathIndex + paintedDiff;
              i++) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              setState(() {
                this.widget.onPaint(i, this.widget.paths[i]);
              });
            });
          }
        }
        //(paintedDiff < 0) -  reverse animation, ignore for now
        //(paintedDiff == 0) means no new path is completed (maybe a segment)
        lastPaintedPathIndex = index;
      }
      if (this.controller.status == AnimationStatus.completed) {
        this.onFinishAnimation();
      }
    };
  }
  AnimationController controller;
  CurvedAnimation curve;
  Curve animationCurve;
  AnimationRange range;
  String assetPath;
  PathOrder animationOrder;
  DebugOptions debug;
  int lastPaintedPathIndex = -1;

  /// Each [PathSegment] represents a continous Path element of the parsed Svg
  List<PathSegment> pathSegments = List<PathSegment>();

  ///Represents the subset of [pathSegment] which is drawn in one animation cycle - defined by [range.start] and [range.end]
  List<PathSegment> _pathSegmentsToAnimate = List<PathSegment>();

  ///Represents the subset of pathSegment which is drawn before the animation starts - defined by < [range.start]
  List<PathSegment> _pathSegmentsToPaintAsBackground = List<PathSegment>();

  /// Extended callback for update widget
  PaintedSegmentCallback onFinishFrame;

  /// Extended callback for update widget
  VoidCallback onFinishAnimation;

  /// Extended callback for update widget - applies for both states
  VoidCallback onFinishAnimationDefault;

  /// Ensure that callback fires off only once even widget is rebuild.
  bool onFinishEvoked = false;

  @override
  void didUpdateWidget(AnimatedDrawing oldWidget) {
    super.didUpdateWidget(oldWidget);
    //Update fields which are valid for both State classes
    if (this.animationOrder != this.widget.animationOrder) {
      applyPathOrder();
    }
  }

  @override
  void initState() {
    super.initState();
    parsePathSegments();
    // TODO add curves on updateWidget...
    if (this.controller != null && widget.animationCurve != null) {
      this.curve = CurvedAnimation(
          parent: this.controller, curve: this.widget.animationCurve);
      this.animationCurve = widget.animationCurve;
    }

    //If DebugOptions changes a hot restart is needed.
    this.debug = this.widget.debug;
    this.debug ??= DebugOptions();
  }

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
    if (this.pathSegments.isNotEmpty) {
      //[A] Persistent paths from _.svg
      if (this.widget.assetPath.isNotEmpty) {
        if (this.widget.animationOrder != null) {
          if (this.widget.lineAnimation == LineAnimation.allAtOnce &&
              this.animationOrder != PathOrders.original) {
            // always keep paths for allAtOnce animation in original path order so we do not sort for the correct PaintOrder later on (which is pretty expensive for AllAtOncePainter)
            this
                .pathSegments
                .sort(Extractor.getComparator(PathOrders.original));
            this.animationOrder = PathOrders.original;
            //Apply new PathOrder
          } else if (this.widget.animationOrder != this.animationOrder) {
            this
                .pathSegments
                .sort(Extractor.getComparator(this.widget.animationOrder));
            this.animationOrder = this.widget.animationOrder;
          }
          //Restore original order when field was nulled.
        } else if (this.animationOrder != null &&
            this.animationOrder != PathOrders.original) {
          this.pathSegments.sort(Extractor.getComparator(PathOrders.original));
          this.animationOrder = PathOrders.original;
        }
        //[B] Experimental: Tmp paths from _.paths: We always have to resort - TODO this easily becomes a performance issue when a parent animation controller calls this 60 fps
      }
      if (this.widget.animationOrder != null &&
          this.widget.lineAnimation != LineAnimation.allAtOnce) {
        this
            .pathSegments
            .sort(Extractor.getComparator(this.widget.animationOrder));
      }
    }
  }

  PathPainter getPathPainter({isStatic = false}) {
    //default
    if (this.widget.range == null) {
      this._pathSegmentsToAnimate = this.pathSegments;
      //range changed
    } else if (this.widget.range != this.range) {
      RangeError.checkValidRange(
          this.widget.range.start,
          this.widget.range.end,
          this.widget.paths.length - 1,
          "start",
          "end",
          "The provided range is invalid for the provided number of paths.");
      //PaintedPainter - draws paths in background before animation starts
      if (isStatic) {
        this._pathSegmentsToPaintAsBackground = this
            .pathSegments
            .where((x) => x.pathIndex < this.widget.range.start)
            .toList();
        this.range = this.widget.range;
      } else {
        //Painter which draw paths gradually
        this._pathSegmentsToAnimate = this
            .pathSegments
            .where((x) => (x.pathIndex >= this.widget.range.start &&
                x.pathIndex <= this.widget.range.end))
            .toList();
      }
    }

    if (isStatic) {
      return (this._pathSegmentsToPaintAsBackground.isNotEmpty)
          ? PaintedPainter(
              getAnimation(),
              _pathSegmentsToPaintAsBackground,
              getCustomDimensions(),
              this.widget.paints,
              this.onFinishFrame,
              this.widget.scaleToViewport,
              this.debug)
          : null;
    } else {
      if (this._pathSegmentsToAnimate.isNotEmpty) {
        switch (this.widget.lineAnimation) {
          case LineAnimation.oneByOne:
            return OneByOnePainter(
                getAnimation(),
                this._pathSegmentsToAnimate,
                getCustomDimensions(),
                this.widget.paints,
                this.onFinishFrame,
                this.widget.scaleToViewport,
                this.debug);
          case LineAnimation.allAtOnce:
            return AllAtOncePainter(
                getAnimation(),
                this._pathSegmentsToAnimate,
                getCustomDimensions(),
                this.widget.paints,
                this.onFinishFrame,
                this.widget.scaleToViewport,
                this.debug);
        }
      }
    }
    return null;
  }

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

  CustomPaint getCustomPaint(BuildContext context) {
    parsePathSegments();
    return new CustomPaint(
        foregroundPainter: getPathPainter(),
        painter: getPathPainter(isStatic: true),
        size: Size.copy(MediaQuery.of(context).size));
  }

  //Call this after controller is defined in child classes
  void listenToController() {
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

  void parsePathSegments() {
    SvgParser parser = new SvgParser();
    //AnimatedDrawing.svg
    if (this.widget.assetPath.isNotEmpty &&
        this.widget.assetPath != this.assetPath) {
      parser.loadFromFile(this.widget.assetPath).then((_) {
        setState(() {
          //raw paths
          this.widget.paths.clear();
          this.widget.paths.addAll(parser.getPaths());
          //corresponding segments
          this.pathSegments = parser.getPathSegments();
          this.assetPath = this.widget.assetPath;
          applyPathOrder();
        });
      });

      //AnimatedDrawing.paths
    } else if (this.widget.paths.isNotEmpty) {
      parser.loadFromPaths(this
          .widget
          .paths); //Path object are parsed completely upon every state change
      setState(() {
        this.pathSegments = parser.getPathSegments();
        applyPathOrder();
      });
    }
  }
}