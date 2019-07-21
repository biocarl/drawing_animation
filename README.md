# drawing_animation [![Pub](https://img.shields.io/pub/v/drawing_animation.svg)](https://pub.dartlang.org/packages/drawing_animation) [![awesome](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

|**From static SVG assets**  | | See more examples in the [showcasing app](https://github.com/biocarl/drawing_animation/tree/master/example/example_03). |
| :---             |     :---:                   |     :---:     |
| <img src="https://github.com/biocarl/img/raw/master/drawing_animation/art_egypt1.gif" width="400px" > |<img src="https://github.com/biocarl/img/raw/master/drawing_animation/art_dino2.gif" width="400px"> <br/> <img src="https://github.com/biocarl/img/raw/master/drawing_animation/art_order.gif" width="400px">   | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/art_child7.gif" width="400px">      |
| **Dynamically created from Path objects which are animated over time** | |  |
| <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_dynamic_1.gif" width="400px" > |*more coming soon*<br/>... | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/loader_1.gif" width="400px">      |

The rendering library exposes a central widget called `AnimatedDrawing` which allows to render SVG paths (via `AnimatedDrawing.svg`) or Flutter Path objects (via `AnimatedDrawing.paths`) in a drawing like fashion.

## Getting Started  - AnimatedDrawing.svg
To get started with the `drawing_animation` package you need a valid Svg file.
Currently only simple path elements without transforms are supported (see [Supported SVG specifications](https://github.com/biocarl/drawing_animation#supported-svg-specifications))

1. **Add dependency in your `pubspec.yaml`**
```yaml
dependencies:
  drawing_animation: ^0.1.3

```

2. **Add the SVG asset**
```yaml
assets:
  - assets/my_drawing.svg
```
3. **Use the widget**

    An AnimatedDrawing widget can be initiated in two ways:
    1. **Simplified - without animation controller (See [Example_01](https://github.com/biocarl/drawing_animation/tree/master/example/example_01))**

        By default every animation repeats infinitely. For running an animation only once you can use a callback to set `run` to false after the first animation cycle completed (see field `onFinish`).
        ```dart
        AnimatedDrawing.svg(
          "assets/my_drawing.svg",
          run: this.run,
          duration: new Duration(seconds: 3),
          onFinish: () => setState(() {
            this.run  = false;
          }),
        )
        ```

    2. **Standard - with animation controller (See [Example_02](https://github.com/biocarl/drawing_animation/tree/master/example/example_02))**

        The simplified version will be sufficient in most of the use cases. If you wish to controll the animation furthermore or you want to syncronize it with other existing animations, you might consider using an custom [animation controller](https://docs.flutter.io/flutter/animation/AnimationController-class.html):
        ```dart
        AnimatedDrawing.svg(
          "assets/test.svg",
          controller: this.controller,
        )
        ```

4. Check out examples in the `examples` folder. It seems that antialising for the Paint/Canvas is switched off when using debug mode. For pretty results use `flutter run --release`.

## Getting Started  - AnimatedDrawing.paths (still experimental)
By providing Path objects directly to the widget, elements can be changed dynamically, even during the animation. The internal data structure is rebuild every time the state changes, therefore the animation performance might suffer if the amount of elements in `paths` is very high (see Limitations). More examples will be provided soon (for now see [Example_01](https://github.com/biocarl/drawing_animation/tree/master/example/example_01) and [Example_04](https://github.com/biocarl/drawing_animation/tree/master/example/example_04)).

  ```dart
  AnimatedDrawing.paths(
      [
      ///Path objects
      ],
      paints:[
      ///Paint objects (optional), specifies a [Paint] object for each [Path] element in `paths`.
      ],
      run: this.run,
      duration: new Duration(seconds: 3),
      onFinish: () => setState(() {
        this.run  = false;
      }),
    )
  ```
**Current limitations:**

As stated, for every state change of the widget, the internal data structure for the path objects is rebuilt. When the amount of provided path objects is high and a custom `animationOrder` is defined (which triggers a sorting operation over the data structure) it can result in lags. This becomes especially apparent when the state is rebuild at 60fps by another animation (e.g. rotating the path objects at every frame). Any suggestions on how to elegantly solve this are very welcome :-)

## Option list
Here is increasingly growing list with all available parameters and their visual effect.

| Field            | Type                            | <pre> ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ </pre>Example<pre> ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ ‍ </pre> |
| :---             |    :---:                       |     :---:     |
| `lineAnimation` <br/><br/> *Specifies in which way the path elements are drawn to the canvas. When `allAtOnce` selected all path segments are drawn simultaneously. `oneByOne` paints every path segment one after another.* | `LineAnimation.oneByOne`        | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_oneByOne.gif" width="200px">   |
|                                    | `LineAnimation.allAtOnce`       | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_allAtOnce.gif" width="200px">  |
| `animationOrder` <br/><br/> *Denotes the order in which the path elements are drawn to canvas when `lineAnimation` is set to `LineAnimation.oneByOne`. When no `animationOrder` is specified it defaults to the same order specified in the Svg asset or path array (`PathOrder.original`).* | `PathOrders.original`           | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_original.gif" width="200px">      |
|                                    | `PathOrders.bottomToTop`        | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_bottomToTop.gif" width="200px">      |
|                                    | `PathOrders.decreasingLength`   | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_decreasingLength.gif" width="200px">      |
|                                    | `PathOrders.increasingLength`   | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_increasingLength.gif" width="200px">      |
|                                    | `PathOrders.leftToRight`        | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_leftToRight.gif" width="200px">      |
|                                    | `PathOrders.rightToLeft`        | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_rightToLeft.gif" width="200px">      |
|                                    | `PathOrders.topToBottom`        | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_topToBottom.gif" width="200px">      |
| `animationCurve` <br/><br/> *Easing curves are used to adjust the rate of change of an animation over time, allowing them to speed up and slow down, rather than moving at a constant rate. See [Flutter docs](https://docs.flutter.io/flutter/animation/Curve-class.html).* | `Curves.linear`                 | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_linear.gif" width="200px">       |
|                                    | `Curves.elasticOut`             | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_elasticOut.gif" width="200px">       |
|                                    | `Curves.bounceInOut`            | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_bounceInOut.gif" width="200px">       |
|                                    | `Curves.decelerate`             | <img src="https://github.com/biocarl/img/raw/master/drawing_animation/met_decelerate.gif" width="200px">       |
|                                    | **Other**            |     |
| `onFinish` <br/><br/> *Callback when one animation cycle is finished. By default every animation repeats infinitely.*|  | |
| `onPaint` <br/><br/> *Callback when a complete path is painted to the canvas. Returns with the relative index and the Path element itself.*|  | |
| `range` <br/><br/> *Start and stop a animation from a certain moment in time by defining a `AnimationRange` object.*|  | |
| `scaleToViewport` <br/><br/> *Path objects are scaled to the available viewport while maintaining the aspect ratio. Defaults to true.*|  | |

## Supported SVG specifications
   - Only path elements (`<path d="M3m1....">`) are supported for now. I'm currently considering to add [flutter_svg](https://pub.dartlang.org/packages/flutter_svg) as dependency for more complete SVG parsing.
   - Attributes
     * stroke, only Hex-Color without alpha for now
     * stroke-width
     * style, but only the both fields above
   - No transforms are supported, yet.

## How can I use my own SVG files?
A lot of tools can convert existing SVG files to the [supported format](#supported-svg-specifications).
For example with Inkscape:
1. Select all objects and ungroup till there is no group left (Ctrl+U)
2. Convert selection to paths: `Path>>Object to Path` and hit save
3. Afterwards remove transforms with [svgo](https://github.com/svg/svgo) or the webversion [svgomg](https://jakearchibald.github.io/svgomg/).
4. Now it should work, if not feel free to write an issue!

## Examples:
  - [`Example_01`](https://github.com/biocarl/drawing_animation/tree/master/example/example_01): Set up simplfied AnimatedDrawing with AnimatedDrawing.svg and AnimatedDrawing.paths
  - [`Example_02`](https://github.com/biocarl/drawing_animation/tree/master/example/example_02): Set up AnimatedDrawing with an custom animation controller
  - [`Example_03`](https://github.com/biocarl/drawing_animation/tree/master/example/example_03): Small artistic showcasing app with vectorizied drawings of [old book scans](https://www.flickr.com/photos/britishlibrary) provided by the British Library
  - [`Example_04`](https://github.com/biocarl/drawing_animation/tree/master/example/example_04): Show how to create Gifs with high resolution using the `debug` field.

## Todo
  - Better test coverage
  - Improve SVG parsing capabilities
    * Circles, rect etc.
    * Better color parsing incl. alpha for hex code and RGB(A)
    * Subsitute SVG parsing logic with an mature parsering library as [flutter_svg](https://pub.dartlang.org/packages/flutter_svg)
  - Provide a way to overwrite color/brush etc. for `AnimatedDrawing.svg` - maybe also over `paints` object?
  - Define a [PathOrder] which maintains each Path and only sorts them relative to each other
  - Improve performance AnimatedDrawing.paths, for every rebuild all provided paths have to be parsed again. Is there a way to check Path-Objects for equality like Keys for widget? Idea: implementing a proxy for Path which creates a unique hash when command evoked
  - Showcase: write "drawing_animation" in different ways + 3 cirlcles + color it and one gif and put it at the top
  - Showcase: Create fractals with L-Systems
  - AnimatedDrawing.paths:
    * Provide some kind of fixed boundingBox since Paths and the overall bounding box can dynamically change (e.g. rotating circle pulses in size)
    * Also custom viewport

## Credits

Thank you to [maxwellito](https://github.com/maxwellito) for his [vivus project](https://github.com/maxwellito/vivus) which served me as initial inspiration for this library. Thank you also to [dnfield](https://github.com/dnfield) for the [path_parsing](https://github.com/dnfield/dart_path_parsing) library.

Credits to the British Library for their awesome [collection of old book scans](https://www.flickr.com/photos/britishlibrary) which I used for the [showcasing app](https://github.com/biocarl/drawing_animation/tree/master/example/example_03).
