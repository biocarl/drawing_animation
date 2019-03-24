import 'package:flutter/animation.dart';

///Compresses another function by left and right border
class YCompressionCurve extends Curve {
  YCompressionCurve(this.a, this.b) {
    assert(b >= b);
  }

  //for bounded curves
  final double total = 1.0;
  //lower bound
  final double a;
  //upper bound
  final double b;

  @override
  double transform(double t) => t * (b - a) / total + a;
}
