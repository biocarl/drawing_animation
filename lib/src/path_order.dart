import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'parser.dart';

/// Denotes the order of [PathSegment] elements (not public).
///
/// A [PathSegment] represents a continuous Path element which itself can be contained in a [Path].
///
/// Ordering the [PathSegment] elements based on the properties of the respective parent Path is still work in progress and will be possible soon.
class PathOrder {
  /// The [PathSegment] order is defined according to their respective length, starting with the longest element. If [reverse] is true, the smallest element is selected first.
  PathOrder.byLength({reverse = false})
      : this._comparator = _byLength(reverse: reverse);

  /// The [PathSegment] order is defined according to its position in the overall bounding box. The position is defined as the center of the respective bounding box of each [PathSegment] element. The field [direction] specifies in which direction the position attribute is compared.
  PathOrder.byPosition({required AxisDirection direction})
      : this._comparator = _byPosition(direction: direction);

  /// Internal
  PathOrder._(this._comparator);

  /// Restores the original order of PathSegments
  PathOrder._original() : this._comparator = __original();

  Comparator<PathSegment> _comparator;

  Comparator<PathSegment> _getComparator() {
    return this._comparator;
  }

  static Comparator<PathSegment> _byLength({reverse = false}) {
    return (reverse)
        ? (PathSegment a, PathSegment b) {
            return a.length!.compareTo(b.length!);
          }
        : (PathSegment a, PathSegment b) {
            return b.length!.compareTo(a.length!);
          };
  }

  static Comparator<PathSegment> _byPosition(
      {required AxisDirection direction}) {
    switch (direction) {
      case AxisDirection.left:
        return (PathSegment a, PathSegment b) {
          return b.path!
              .getBounds()
              .center
              .dx
              .compareTo(a.path!.getBounds().center.dx);
        };
      case AxisDirection.right:
        return (PathSegment a, PathSegment b) {
          return a.path!
              .getBounds()
              .center
              .dx
              .compareTo(b.path!.getBounds().center.dx);
        };
      case AxisDirection.up:
        return (PathSegment a, PathSegment b) {
          return b.path!
              .getBounds()
              .center
              .dy
              .compareTo(a.path!.getBounds().center.dy);
        };
      case AxisDirection.down:
        return (PathSegment a, PathSegment b) {
          return a.path!
              .getBounds()
              .center
              .dy
              .compareTo(b.path!.getBounds().center.dy);
        };
      default:
        return PathOrder._original()._getComparator();
    }
  }

  static Comparator<PathSegment> __original() {
    return (PathSegment a, PathSegment b) {
      int comp = a.firstSegmentOfPathIndex.compareTo(b.firstSegmentOfPathIndex);
      if (comp == 0) comp = a.relativeIndex.compareTo(b.relativeIndex);
      return comp;
    };
  }

  /// Returns a new PathOrder object which first sorts [PathSegment] elements according to this instance and further sorts according to [secondPathOrder].
  PathOrder combine(PathOrder secondPathOrder) {
    return PathOrder._((PathSegment a, PathSegment b) {
      int comp = _comparator(a, b);
      if (comp == 0) comp = secondPathOrder._comparator(a, b);
      return comp;
    });
  }

//TODO Implement? You can also do list.reversed.
// PathOrder reverse(){
// }

  /// Based on outer bounds (depending on the direction) of bounding box.
// static Comparator<PathSegment> _byPosition2({@required AxisDirection direction}){
//   switch(direction){
//     case AxisDirection.left:
//       return (PathSegment a, PathSegment b) { return b.path.getBounds().right.compareTo(a.path.getBounds().right);};
//     case AxisDirection.right:
//       return (PathSegment a, PathSegment b) { return a.path.getBounds().left.compareTo(b.path.getBounds().left);};
//     case AxisDirection.up :
//       return (PathSegment a, PathSegment b) { return b.path.getBounds().bottom.compareTo(a.path.getBounds().bottom);};
//   case AxisDirection.down :
//     return (PathSegment a, PathSegment b) { return a.path.getBounds().top.compareTo(b.path.getBounds().top);};
//   default:
//     return (PathSegment a, PathSegment b) { return 1;};
// }
// }
}

/// A collection of common [PathOrder] constants.
class PathOrders {
  /// The [PathSegment] elements are painted in the order as they are laid out in the Svg asset or path list. This is useful as a default PathOrder for cases where a PathOrder is required but no different order is desired.
  static PathOrder original = PathOrder._original();

  /// [PathSegment] elements which are located left-most of the overall bounding box are considered first.
  static PathOrder leftToRight =
      PathOrder.byPosition(direction: AxisDirection.right);

  /// [PathSegment] elements which are located right-most of the overall bounding box are considered first.
  static PathOrder rightToLeft =
      PathOrder.byPosition(direction: AxisDirection.left);

  /// [PathSegment] elements which are located at the very top of the overall bounding box are considered first.
  static PathOrder topToBottom =
      PathOrder.byPosition(direction: AxisDirection.down);

  /// [PathSegment] elements which are located at the very bottom of the overall bounding box are considered first.
  static PathOrder bottomToTop =
      PathOrder.byPosition(direction: AxisDirection.up);

  /// [PathSegment] elements which are smallest in size are considered first.
  static PathOrder increasingLength = PathOrder.byLength(reverse: true);

  /// [PathSegment] elements which are biggest in size are considered first.
  static PathOrder decreasingLength = PathOrder.byLength();
}

class Extractor {
  static Comparator<PathSegment> getComparator(PathOrder pathOrder) {
    return pathOrder._getComparator();
  }
}
