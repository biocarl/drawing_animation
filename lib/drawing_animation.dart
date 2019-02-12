/// An dart-only library for gradually painting path objects on canvas (drawing line animation), supporting SVG paths and Flutter Path objects.
///
///
/// The rendering library exposes a central widget called `AnimatedDrawing` which allows to render SVG paths (via `AnimatedDrawing.svg`) or Flutter Path objects (via `AnimatedDrawing.paths`) in a drawing like fashion. This library is still at early-stage development and might be subject to breaking API changes.
///
/// # Getting Started
/// To get started with the `drawing_animation` package you need a valid Svg file.
/// Currently only simple path elements without transforms are supported (see [Supported SVG specifications](#supported-svg-specifications))
///
/// 1. Add dependency in your `pubspec.yaml`
/// ```yaml
/// dependencies:
/// drawing_animation: ^0.01
///
/// ```
///
/// 2. Add the SVG asset
/// ```yaml
/// assets:
///   - assets/my_drawing.svg
/// ```
/// 3. Use the widget
///     An AnimatedDrawing widget can be initiated in two ways:
///     1. Simplified - Without animation controller
///
///         By default every animation repeats infinitely. For running an animation only once you can use a callback to set `run` to false after the first animation cycle completed (see field `onFinish`).
///         ```dart
///         AnimatedDrawing.svg(
///           "assets/test.svg",
///           run: this.run,
///           duration: new Duration(seconds: 3),
///           onFinish: () => setState(() {
///             this.run  = false;
///           }),
///         )
///         ```
///
///     2. Standard - with animation controller
///
///         The simplified version will be sufficient in most of the use cases. If you wish to controll the animation furthermore or you want to syncronize it with other existing animations, you might consider using an custom [animation controller](https://docs.flutter.io/flutter/animation/AnimationController-class.html):
///         ```dart
///         AnimatedDrawing.svg(
///           "assets/test.svg",
///           controller: this.controller,
///         )
///         ```
///
/// 4. Check out examples in the `examples` folder. It seems that antialising for the Paint/Canvas is switched off when using debug mode. For pretty results use `flutter run --release`.
///
/// # Getting Started  - AnimatedDrawing.paths (still experimental)
/// By providing Path objects directly to the widget, elements can be changed dynamically, even during the animation. The internal data structure is rebuild every time the state changes, therefore the animation performance might suffer if the amount of elements in `paths` is very high.
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
library drawing_animation;

export 'src/drawing_widget.dart';
export 'src/path_order.dart' hide Extractor;
export 'src/debug.dart';
