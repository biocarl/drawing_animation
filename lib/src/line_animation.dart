/// The enum [LineAnimation] selects a internal painter for animating each [PathSegment] element
enum LineAnimation {
  /// Paints every path segment one after another to the canvas.
  oneByOne,

  /// When selected each path segment is drawn simultaneously to the canvas.
  allAtOnce
}
