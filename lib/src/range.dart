import 'package:equatable/equatable.dart';

/// Denotes a range of path segments over which a animation is built.
///
/// Segments below that range will be painted with the first frame of the animation and therefore not iteratively. Segments above that range will be excluded from the animation. This class must not be inherited.
abstract class AnimationRange extends Equatable {
  AnimationRange(this.start, this.end) {
    assert(start! <= end! && start! >= 0 && end! >= 0);
  }
  final int? start;
  final int? end;

  @override
  List<Object?> get props => [start, end];

  bool get isLower => start != null;
  bool get isUpper => end != null;
}

/// Denotes a range by its relative position in the Path array provided.
///
/// The [start] should be >= 0 and [end] < than the number of the provided Path objects.
class PathIndexRange extends AnimationRange {
  PathIndexRange({required int start, required int end}) : super(start, end);
}
