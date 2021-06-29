import 'package:flutter_test/flutter_test.dart';

import 'mocks.dart';
import 'dart:ui';
import 'package:drawing_animation/src/drawing_widget.dart';

void main() {
  test('Test arguments for SvgDrawing widget creation', () {
    //[A] GENERAL constructor
    //Working - standard init
    expect(
        AnimatedDrawing.svg('test.svg', controller: MockAnimationController()),
        const TypeMatcher<AnimatedDrawing>());

    //Working - simplified init
    expect(
        AnimatedDrawing.svg(
          'test.svg',
          controller: null,
          run: true,
          duration: Duration(seconds: 5),
        ),
        const TypeMatcher<AnimatedDrawing>());

    //Not working - missing arguments: no controller OR run/duration supplied
    expect(() => AnimatedDrawing.svg('test.svg'),
        throwsA(const TypeMatcher<AssertionError>()));

    //[B] AnimatedDrawing.svg constructor
    //Not working - missing arguments: asset empty
    expect(() => AnimatedDrawing.svg('', controller: MockAnimationController()),
        throwsA(const TypeMatcher<AssertionError>()));

    //[C] AnimatedDrawing.paths
    //Not working - missing arguments: empty list of paths
    expect(
        () => AnimatedDrawing.paths(<Path>[],
            controller: MockAnimationController()),
        throwsA(const TypeMatcher<AssertionError>()));
  });
}
