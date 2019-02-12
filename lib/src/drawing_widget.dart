import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'debug.dart';
import 'painter.dart';
import 'parser.dart';
import 'path_order.dart';

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
    //For both
    this.animationOrder,
    this.width,
    this.height,
    this.lineAnimation = LineAnimation.oneByOne,
    this.debug = DebugOptions.standard,
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
    this.paints,
    //Standard
    this.controller,
    //Simplfied version
    this.run,
    this.duration,
    this.animationCurve,
    this.onFinish,
    //For both
    this.animationOrder,
    this.width,
    this.height,
    this.lineAnimation = LineAnimation.oneByOne,
    this.debug = DebugOptions.standard,
  }) : assetPath = '' {
    checkAssertions();
    assert(this.paths.isNotEmpty);
    assert(this.paints.length == this.paths.length);
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

/// Base class for _AnimatedDrawingState
abstract class _AbstractAnimatedDrawingState extends State<AnimatedDrawing> {
  AnimationController controller;
  CurvedAnimation curve;
  Curve animationCurve;
  String assetPath;
  PathOrder animationOrder;

  /// Each [PathSegment] represents a continous Path element of the parsed Svg
  List<PathSegment> pathSegments;

  /// Extended callback for update widget
  VoidCallback onFinishUpdateState;

  /// Extended callback for update widget - applies for both states
  VoidCallback onFinishUpdateStateDefault;

  /// Ensure that callback fires off only once even widget is rebuild.
  bool onFinishEvoked = false;

  void prepareBuild() {
    this.onFinishUpdateStateDefault = () {
      if (this.widget.onFinish != null) {
        this.widget.onFinish();
        //Here you can do cleanUp for all states
        //...
      }
    };
    this.onFinishUpdateState = onFinishUpdateStateDefault;
  }

  @override
  void initState() {
    super.initState();
    parsePathSegments();
    if (this.controller != null && widget.animationCurve != null) {
      this.curve = CurvedAnimation(
          parent: this.controller, curve: widget.animationCurve);
      this.animationCurve = widget.animationCurve;
    }
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

  //TODO clean this up.
  void applyPathOrder() {
    if (this.pathSegments != null) {
      //Experimental path we always have to resort
      if (this.widget.paths != null) {
        if (this.widget.animationOrder != null) {
          this
              .pathSegments
              .sort(Extractor.getComparator(this.widget.animationOrder));
          this.animationOrder = this.widget.animationOrder;
        }
      } else {
        //New animationOrder submitted
        if (this.widget.animationOrder != null) {
          if (this.widget.animationOrder != this.animationOrder) {
            this
                .pathSegments
                .sort(Extractor.getComparator(this.widget.animationOrder));
            this.animationOrder = this.widget.animationOrder;
          }
          //Restore original order
        } else if (this.animationOrder != null &&
            this.animationOrder != PathOrders.original) {
          this.pathSegments.sort(Extractor.getComparator(PathOrders.original));
          this.animationOrder = this.widget.animationOrder;
        }
      }
    }
  }

  PathPainter getPathPainter() {
    switch (this.widget.lineAnimation) {
      case LineAnimation.oneByOne:
        applyPathOrder();
        return OneByOnePainter(
            getAnimation(),
            this.pathSegments,
            getCustomDimensions(),
            this.widget.paints,
            this.onFinishUpdateState,
            this.widget.debug);
      case LineAnimation.allAtOnce:
        return AllAtOncePainter(
            getAnimation(),
            this.pathSegments,
            getCustomDimensions(),
            this.widget.paints,
            this.onFinishUpdateState,
            this.widget.debug);
      default:
        return OneByOnePainter(
            getAnimation(),
            this.pathSegments,
            getCustomDimensions(),
            this.widget.paints,
            this.onFinishUpdateState,
            this.widget.debug);
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

  void parsePathSegments() {
    SvgParser parser = new SvgParser();
    //AnimatedDrawing.svg
    if (this.widget.assetPath.isNotEmpty &&
        this.widget.assetPath != this.assetPath) {
      parser.loadFromFile(this.widget.assetPath).then((_) {
        setState(() {
          this.pathSegments = parser.getPathSegments();
          this.assetPath = this.widget.assetPath;
          applyPathOrder();
        });
      });

      //AnimatedDrawing.paths
    } else if (this.widget.paths.isNotEmpty) {
      parser.loadFromPaths(this.widget.paths);
      setState(() {
        this.pathSegments = parser.getPathSegments();
        applyPathOrder();
      });
    }
  }
}

/// A state implementation which allows controlling the animation through an animation controller when provided.
class _AnimatedDrawingState extends _AbstractAnimatedDrawingState {
  @override
  void initState() {
    super.initState();
    this.controller = this.widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    prepareBuild();
    return getCustomPaint(context);
  }

  @override
  void prepareBuild() {
    super.prepareBuild();
    this.onFinishUpdateState = () {
      if (!this.onFinishEvoked) {
        Timer(
            Duration(milliseconds: 1),
            () => this
                .onFinishUpdateStateDefault()); //See _AnimatedDrawingWithTickerState>>prepareBuild
        this.onFinishEvoked = true;
      }
    };
  }
}

/// A state implementation with an implemented animation controller to simplify the animation process
class _AnimatedDrawingWithTickerState extends _AbstractAnimatedDrawingState
    with SingleTickerProviderStateMixin {
  //Manage state
  bool paused = false;

  @override
  void initState() {
    super.initState();
    controller = new AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    prepareBuild();
    buildAnimation();
    return getCustomPaint(context);
  }

  @override
  void prepareBuild() {
    super.prepareBuild();
    this.onFinishUpdateState = () {
      //TODO This is a very bad workaround, FIX! Error message when setting state without timer: "Build scheduled during frame. While the widget tree was being built, laid out, and painted, a new frame was scheduled to rebuild the widget tree. This might be because setState() was called from a layout or paint callback. If a change is needed to the widget tree, it should be applied as the tree is being built. Scheduling a change for the subsequent frame instead results in an interface that lags behind by one frame. If this was done to make your build dependent on a size measured at layout time, consider using a LayoutBuilder, CustomSingleChildLayout, or CustomMultiChildLayout. If, on the other hand, the one frame delay is the desired effect, for example because this is an animation, consider scheduling the frame in a post-frame callback using SchedulerBinding.addPostFrameCallback or using an AnimationController to trigger the animation."
      if (!this.onFinishEvoked) {
        Timer(
            Duration(milliseconds: 1), () => this.onFinishUpdateStateDefault());
        Timer(Duration(milliseconds: 1), () => setState(() {}));
        this.onFinishEvoked = true;
      }
    };
  }

  Future<void> buildAnimation() async {
    try {
      if ((this.paused ||
              this.controller.status == AnimationStatus.dismissed ||
              this.controller.status == AnimationStatus.completed) &&
          this.widget.run == true) {
        this.paused = false;
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
