import 'dart:math';
import 'package:drawing_animation/drawing_animation.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool run = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () => setState(() {
                this.run = !this.run;
              }),
          child: Icon((this.run) ? Icons.stop : Icons.play_arrow)),
      body: Center(
          child: Column(children: <Widget>[
        //Simplfied AnimatedDrawing using Flutter Path objects
        Expanded(
            child: AnimatedDrawing.paths(
          [
            (Path()
                  ..addOval(Rect.fromCircle(center: Offset.zero, radius: 75.0)))
                .transform(Matrix4.rotationX(-pi)
                    .storage), //A circle which is slightly rotated
          ],
          paints: [
            Paint()..style = PaintingStyle.stroke,
          ],
          run: this.run,
          animationOrder: PathOrders.original,
          duration: new Duration(seconds: 2),
          lineAnimation: LineAnimation.oneByOne,
          animationCurve: Curves.linear,
          onFinish: () => setState(() {
            this.run = false;
          }),
        )),

        //Simplfied AnimatedDrawing parsing Path objects from an Svg asset
        Expanded(
            child: AnimatedDrawing.svg(
          "assets/circle.svg",
          run: this.run,
          duration: new Duration(seconds: 2),
          lineAnimation: LineAnimation.oneByOne,
          animationCurve: Curves.linear,
          onFinish: () => setState(() {
            this.run = false;
          }),
        )),
      ])),
    );
  }
}
