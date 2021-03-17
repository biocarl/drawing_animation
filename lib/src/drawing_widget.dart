import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'abstract_drawing_state.dart';
import 'debug.dart';
import 'drawing_state.dart';
import 'drawing_state_with_ticker.dart';
import 'line_animation.dart';
import 'path_order.dart';
import 'range.dart';

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
    //Simplified version
    this.run,
    this.duration,
    this.animationCurve,
    this.onFinish,
    this.onPaint,
    //For both
    this.animationOrder,
    this.width,
    this.height,
    this.range,
    this.lineAnimation = LineAnimation.oneByOne,
    this.scaleToViewport = true,
    this.debug,
  })  : this.paths = [],
        this.paints = []
        {
    assertAnimationParameters();
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
    //Simplified version
    this.run,
    this.duration,
    this.animationCurve,
    this.onFinish,
    this.onPaint,
    //For both
    this.animationOrder,
    this.width,
    this.height,
    this.range,
    this.lineAnimation = LineAnimation.oneByOne,
    this.scaleToViewport = true,
    this.debug,
  }) : this.assetPath = ''
  {
    assertAnimationParameters();
    assert(this.paths.isNotEmpty);
    if (this.paints.isNotEmpty) assert(this.paints.length == this.paths.length);
  }

  /// Provide path data via an SVG asset.
  ///
  /// For instance an SVG file named my_svg would be specified as "assets/my_svg.svg". Also see * [Supported SVG specifications](https://github.com/biocarl/drawing_animation#supported-svg-specifications).
  final String assetPath;

  /// Provide path data via an list of Path objects.
  ///
  /// The default [animationOrder] ([PathOrder.original]), when not specified differently, will equal to the order of the provided path elements.
  final List<Path> paths;

  /// When specified each [Path] object in [paths] is painted by applying the corresponding [Paint] object.
  ///
  /// The length of both [paths] and [paints] has to be equal.
  /// Keep in mind that [Paint.style] defaults to [PaintingStyle.fill], whereas in most of the cases you probably want to set it to [PaintingStyle.stroke].
  /// The corresponding order of Paint objects always orients itself on the [PathOrder.original], even if the [PathOrder] was changed.
  final List<Paint> paints;

  /// When a animation controller is specified, the progress of the animation can be controlled externally.
  ///
  /// The visibility of the rendered SVG depends on the current controller.value but also on the type of [LineAnimation]. When no controller is provided the progress of the animation is controlled via the fields [run], [duration].
  final AnimationController? controller;

  /// Easing curves are used to adjust the rate of change of an animation over time, allowing them to speed up and slow down, rather than moving at a constant rate.
  ///
  /// When the animation is controlled via an external [AnimationController] object in [controller], the curve is applied to that controller respectively.
  final Curve? animationCurve;

  /// Callback is evoked after one animation cycle has finished.
  ///
  /// By default every animation repeats infinitely. For running an animation only once you can use this callback to set [run] to false after the first animation cycle completed. This field is ignored when [controller] is provided and the animation is set to [controller.repeat()].
  final VoidCallback? onFinish;

  /// Callback is evoked when a complete path is painted to the canvas.
  ///
  /// Returns with the relative index and the Path element itself.
  /// If the animation reverses (for examples when applying animation curves) the callback might fire several times for the same path.
  ///
  /// The callback fires when the complete Path is painted to the canvas. This does also mean that other Path objects might already been drawn in the same frame. If you want for instance pause a animation after a certain Path element is painted you should consider using the [range] functionality and use the onFinish callback instead.
  final PaintedPathCallback? onPaint;

  ///Denotes the order in which the path elements are drawn to canvas when [lineAnimation] is set to [LineAnimation.oneByOne]. When no [animationOrder] is specified it defaults to [PathOrder.original]. Do not confuse this option with the default rendering order, whereas the first path elements are painted first to the canvas and therefore potentially occluded by subsequent elements ([w3-specs](https://www.w3.org/TR/SVG/render.html#RenderingOrder)). For now the rendering order always defaults to [PathOrder.original].
  final PathOrder? animationOrder;

  /// When no custom animation controller is provided the state of the animation can be controlled via [run].
  ///
  /// Is [run] set to true the first animation cycle is triggered.
  ///
  /// By default every animation repeats infinitely. For running an animation only once you can use the callback [onFinish] to set [run] to false after the first cycle completed. When [run] is set to false while the animation is still running, the animation is stopped at that point in time. If [run] is set to true again the animation is reset to the beginning. To continue the animation at the previous value you might consider using [controller].
  final bool? run;

  /// When no custom animation controller is provided the duration of the animation can be controlled via [duration].
  final Duration? duration;

  /// When [width] is specified parent constraints are ignored. When only [width] or [height] is specified the original aspect ratio is preserved.
  final double? width;

  /// When [height] is specified parent constraints are ignored. When only [width] or [height] is specified the original aspect ratio is preserved.
  final double? height;

  /// Specifies a start and end point from where to start and stop the animation.
  ///
  /// For now only [PathIndexRange] is supported as parameter type.
  final AnimationRange? range;

  /// Specifies in which way the path elements are drawn to the canvas.
  ///
  /// See [LineAnimation.allAtOnce] and [LineAnimation.oneByOne]
  final LineAnimation lineAnimation;

  /// Denotes if the path elements should be scaled in order to fit into viewport.
  ///
  /// Defaults to true.
  final bool scaleToViewport;

  /// For debugging, not for production use.
  final DebugOptions? debug;

  @override
  AbstractAnimatedDrawingState createState() {
    if (this.controller != null) {
      return new AnimatedDrawingState();
    }
    return new AnimatedDrawingWithTickerState();
  }

  // TODO Refactor SRP
  void assertAnimationParameters() {
    assert(!(this.controller == null && (this.run == null || this.duration == null)));
  }
}
