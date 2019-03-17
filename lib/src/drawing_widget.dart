import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'debug.dart';
import 'painter.dart';
import 'parser.dart';
import 'path_order.dart';
import 'types.dart';

/// Callback when path is painted.
typedef PaintedPathCallback = void Function(int, Path);

/// A widget that iteratively draws path segment data to a defined canvas (drawing line animation).
///
/// Path data can be either passed directly ([AnimatedDrawing.paths]) or via an Svg file ([AnimatedDrawing.svg]).
class AnimatedDrawing extends StatefulWidget {
  /// Parses path data from an SVG asset. In order to use assets in your project specify those in `pubspec.yaml`:
  /// ```yaml
  /// assets:
  ///   - assets/my_drawing.svg
  /// ```
  /// By default every animation repeats infinitely. For running an animation only once you can use a callback to set `run` to false after the first animation cycle completed (see field `onFinish`).
  /// ```dart
  /// AnimatedDrawing.svg(
  ///   "assets/test.svg",
  ///   run: this.run,
  ///   duration: new Duration(seconds: 3),
  ///   onFinish: () => setState(() {
  ///     this.run  = false;
  ///   }),
  /// )
  /// ```
  AnimatedDrawing.svg(
    this.assetPath, {
    //Standard
    this.controller,
    //Simplfied version
    this.run,
    this.duration,
    this.animationCurve,
    this.onFinish,
    this.onPaint,
    //For both
    this.animationOrder,
    this.width,
    this.height,
    this.lineAnimation = LineAnimation.oneByOne,
    this.scaleToViewport = true,
    this.debug,
  })  : paths = [],
        paints = [] {
    checkAssertions();
    assert(this.assetPath.isNotEmpty);
  }

  /// Creates an instance of [AnimatedDrawing] by directly passing path elements to the constructor (still experimental).
  ///
  ///   ```dart
  ///   AnimatedDrawing.paths(
  ///       [
  ///       ///Path objects
  ///       ],
  ///       paints:[
  ///       ///Paint objects (optional), specifies a [Paint] object for each [Path] element in `paths`.
  ///       ],
  ///       run: this.run,
  ///       duration: new Duration(seconds: 3),
  ///       onFinish: () => setState(() {
  ///         this.run  = false;
  ///       }),
  ///     )
  ///   ```
  ///
  /// Updating [paths] allows dynamically building animation scenes based on external states. For this widget the internal data structure is rebuild every time the state changes, therefore the animation performance might suffer if the amount of elements in [paths] is very high.
  ///
  /// Optionally, [paints] can be provided which specifies a [Paint] object for each [Path] element in [paths].
  AnimatedDrawing.paths(
    this.paths, {
    //AnimatedDrawing.paths
    this.paints = const <Paint>[],
    //Standard
    this.controller,
    //Simplfied version
    this.run,
    this.duration,
    this.animationCurve,
    this.onFinish,
    this.onPaint,
    //For both
    this.animationOrder,
    this.width,
    this.height,
    this.lineAnimation = LineAnimation.oneByOne,
    this.scaleToViewport = true,
    this.debug,
  }) : this.assetPath = '' {
    checkAssertions();
    assert(this.paths.isNotEmpty);
    if (this.paints.isNotEmpty) assert(this.paints.length == this.paths.length);
  }

  //AnimatedDrawing.svg:
  /// The full path to the SVG asset.
  ///
  /// For instance an SVG file named my_svg would be specified as "assets/my_svg.svg". Also see * [Supported SVG specifications](https://github.com/biocarl/drawing_animation#supported-svg-specifications).
  final String assetPath;

  //AnimatedDrawing.paths
  /// Path data for drawing line animation when path data is provided directly.
  ///
  /// The default [animationOrder] ([PathOrder.original]), when not specified differently, will equal to the order of the provided path elements.
  final List<Path> paths;

  /// When specified each [Path] object in [paths] is painted by applying the corresponding [Paint] object.
  ///
  /// The length of both [paths] and [paints] has to be equal.
  /// Keep in mind that [Paint.style] defaults to [PaintingStyle.fill], whereas in most of the cases you probably want to set it to [PaintingStyle.stroke].
  /// The corresponding order of Paint objects always orients itself on the [PathOrder.original], even if the [PathOrder] was changed.
  final List<Paint> paints;

  //_AnimatedDrawingState
  /// When a animation controller is specified, the progress of the animation can be controlled externally.
  ///
  /// The visibility of the rendered SVG depends on the current controller.value but also on the type of [LineAnimation]. When no controller is provided the progress of the animation is controlled via the fields [run], [duration].
  final AnimationController controller;

  //_AnimatedDrawingWithTickerState
  /// Easing curves are used to adjust the rate of change of an animation over time, allowing them to speed up and slow down, rather than moving at a constant rate.
  ///
  /// When the animation is controlled via an external [AnimationController] object in [controller], the curve is applied to that controller respectively.
  final Curve animationCurve;

  /// Callback when one animation cycle is finished.
  ///
  /// By default every animation repeats infinitely. For running an animation only once you can use this callback to set [run] to false after the first animation cycle completed. This field is ignored when [controller] is provided and the animation is set to [controller.repeat()].
  final VoidCallback onFinish;

  /// Callback when a complete path is painted to the canvas.
  ///
  /// Returns with the relative index and the Path element itself.
  /// If the animation reverses (for examples when applying animation curves) the callback might fire several times for the same path.
  final PaintedPathCallback onPaint;

  ///Denotes the order in which the path elements are drawn to canvas when [lineAnimation] is set to [LineAnimation.oneByOne]. When no [animationOrder] is specified it defaults to [PathOrder.original]. Do not confuse this option with the default rendering order, whereas the first path elements are painted first to the canvas and therefore potentially occluded by subsequent elements ([w3-specs](https://www.w3.org/TR/SVG/render.html#RenderingOrder)). For now the rendering order always defaults to [PathOrder.original].
  final PathOrder animationOrder;

  //For _AnimatedDrawingWithTickerState
  /// When [run] is set to true the first animation cycle is triggered.
  ///
  /// By default every animation repeats infinitely. For running an animation only once you can use the callback [onFinish] to set [run] to false after the first cycle completed. When [run] is set to false while the animation is still running, the animation is stopped at that point in time. If [run] is set to true again the animation is reset to the beginning. To continue the animation at the previous value you might consider using [controller].
  final bool run;

  /// Denotes the duration of the animation if no [controller] is specified.
  final Duration duration;

  /// When [width] is specified parent constraints are ignored. When only [width] or [height] is specified the original aspect ratio is preserved.
  final double width;

  /// When [height] is specified parent constraints are ignored. When only [width] or [height] is specified the original aspect ratio is preserved.
  final double height;

  /// Specifies in which way the path elements are drawn to the canvas.
  final LineAnimation lineAnimation;

  /// Denotes if the path elements should be scaled in order to fit into viewport.
  ///
  /// Defaults to true.
  final bool scaleToViewport;

  /// For debugging, not for production use.
  final DebugOptions debug;

  void checkAssertions() {
    assert(!(this.controller == null &&
        (this.run == null || this.duration == null)));
  }

  @override
  _AbstractAnimatedDrawingState createState() {
    if (this.controller != null) {
      return new _AnimatedDrawingState();
    } else {
      return new _AnimatedDrawingWithTickerState();
    }
  }
}

/// Base class for _AnimatedDrawingState and _AnimatedDrawingWithTickerState
abstract class _AbstractAnimatedDrawingState extends State<AnimatedDrawing> {
  _AbstractAnimatedDrawingState() {
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
            this.widget.onPaint(i, this.widget.paths[i]);
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
  String assetPath;
  PathOrder animationOrder;
  DebugOptions debug;
  int lastPaintedPathIndex = -1;

  /// Each [PathSegment] represents a continous Path element of the parsed Svg
  List<PathSegment> pathSegments;

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
    if (this.curve != null && this.animationCurve == widget.animationCurve) {
      return this.curve;
    } else if (widget.animationCurve != null && this.controller != null) {
      this.curve = CurvedAnimation(
          parent: this.controller, curve: widget.animationCurve);
      this.animationCurve = widget.animationCurve;
      return this.curve;
    } else {
      return this.controller;
    }
  }

  void applyPathOrder() {
    if (this.pathSegments != null) {
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

  PathPainter getPathPainter() {
    switch (this.widget.lineAnimation) {
      case LineAnimation.oneByOne:
        return OneByOnePainter(
            getAnimation(),
            this.pathSegments,
            getCustomDimensions(),
            this.widget.paints,
            this.onFinishFrame,
            this.widget.scaleToViewport,
            this.debug);
      case LineAnimation.allAtOnce:
        return AllAtOncePainter(
            getAnimation(),
            this.pathSegments,
            getCustomDimensions(),
            this.widget.paints,
            this.onFinishFrame,
            this.widget.scaleToViewport,
            this.debug);
      default:
        return OneByOnePainter(
            getAnimation(),
            this.pathSegments,
            getCustomDimensions(),
            this.widget.paints,
            this.onFinishFrame,
            this.widget.scaleToViewport,
            this.debug);
    }
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
        painter: getPathPainter(),
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

/// A state implementation which allows controlling the animation through an animation controller when provided.
class _AnimatedDrawingState extends _AbstractAnimatedDrawingState {
  _AnimatedDrawingState() : super() {
    this.onFinishAnimation = () {
      if (!this.onFinishEvoked) {
        Timer(Duration(milliseconds: 1), () => this.onFinishAnimationDefault());
        this.onFinishEvoked = true;
      }
    };
  }
  @override
  void initState() {
    super.initState();
    this.controller = this.widget.controller;
    listenToController();
  }

  @override
  void didUpdateWidget(AnimatedDrawing oldWidget) {
    super.didUpdateWidget(oldWidget);
    this.controller = this.widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    return getCustomPaint(context);
  }
}

/// A state implementation with an implemented animation controller to simplify the animation process
class _AnimatedDrawingWithTickerState extends _AbstractAnimatedDrawingState
    with SingleTickerProviderStateMixin {
  _AnimatedDrawingWithTickerState() : super() {
    this.onFinishAnimation = () {
      //TODO This is a very bad workaround, FIX! Error message when setting state without timer: "Build scheduled during frame. While the widget tree was being built, laid out, and painted, a new frame was scheduled to rebuild the widget tree. This might be because setState() was called from a layout or paint callback. If a change is needed to the widget tree, it should be applied as the tree is being built. Scheduling a change for the subsequent frame instead results in an interface that lags behind by one frame. If this was done to make your build dependent on a size measured at layout time, consider using a LayoutBuilder, CustomSingleChildLayout, or CustomMultiChildLayout. If, on the other hand, the one frame delay is the desired effect, for example because this is an animation, consider scheduling the frame in a post-frame callback using SchedulerBinding.addPostFrameCallback or using an AnimationController to trigger the animation."
      if (!this.onFinishEvoked) {
        Timer(Duration(milliseconds: 1), () => this.onFinishAnimationDefault());
        //Animation is completed when last frame is painted not when animation controller is finished
        if (this.controller.status == AnimationStatus.dismissed ||
            this.controller.status == AnimationStatus.completed) {
          this.finished = true;
        }
        Timer(Duration(milliseconds: 1), () => setState(() {}));
        this.onFinishEvoked = true;
      }
    };
  }
  //Manage state
  bool paused = false;
  bool finished = true;

  @override
  void didUpdateWidget(AnimatedDrawing oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.duration = widget.duration;
  }

  @override
  void initState() {
    super.initState();
    controller = new AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    listenToController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    buildAnimation();
    return getCustomPaint(context);
  }

  Future<void> buildAnimation() async {
    try {
      if ((this.paused ||
              (this.finished &&
                  !(this.controller.status == AnimationStatus.forward))) &&
          this.widget.run == true) {
        this.paused = false;
        this.finished = false;
        this.controller.reset();
        this.onFinishEvoked = false;
        this.controller.forward();
      } else if ((this.controller.status == AnimationStatus.forward) &&
          this.widget.run == false) {
        this.controller.stop();
        this.paused = true;
      }
    } on TickerCanceled {
      // TODO usecase?
    }
  }
}

/// The enum [LineAnimation] selects a internal painter for animating each [PathSegment] element
enum LineAnimation {
  /// Paints every path segment one after another to the canvas.
  oneByOne,

  /// When selected each path segment is drawn simultaneously to the canvas.
  allAtOnce
}
