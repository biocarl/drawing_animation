import 'package:drawing_animation/drawing_animation.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SvgDrawingWithCustomController('assets/circle.svg'),
      ),
    );
  }
}

class SvgDrawingWithCustomController extends StatefulWidget {
  const SvgDrawingWithCustomController(this.assetName, {super.key});

  final String assetName;

  @override
  SvgDrawingWithCustomControllerState createState() =>
      SvgDrawingWithCustomControllerState();
}

class SvgDrawingWithCustomControllerState
    extends State<SvgDrawingWithCustomController>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (_running) {
      _controller.stop();
    } else {
      _controller.stop();
      _controller.repeat();
    }
    _running = !_running;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          color: Colors.green,
        ),
        child: GestureDetector(
            onTap: () => _startAnimation(),
            behavior: HitTestBehavior.translucent,
            //AnimatedDrawing with a custom controller
            child: AnimatedDrawing.svg(
              widget.assetName,
              controller: _controller,
              lineAnimation: LineAnimation.oneByOne,
              animationCurve: Curves.linear,
            )));
  }
}
