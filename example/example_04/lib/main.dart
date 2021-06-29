import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:drawing_animation/drawing_animation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool start = false;
  bool run = false;
  late Directory storageDir;
  String parentFolder = 'drawing_animation';
  //Resulting in  a folder called `simple` containing simple_0.png ... simple_100.png
  String projectName = 'project1';

  @override
  void initState() {
    super.initState();
    requestPermissions();

    //Metatron related
    metatron = createMetatron();
  }

  //Stores project folders on external storage of the phone
  Future<void> requestPermissions() async {
    var res = await Permission.storage.request();
    if (res == PermissionStatus.granted) {
      //External storage
      storageDir = (await getExternalStorageDirectory())!;
      //current project
      storageDir = Directory(
          '${storageDir.path}/$parentFolder/$projectName');
      //Replace existing project folder
      if (await storageDir.exists()) {
        storageDir.deleteSync(recursive: true);
      }
      storageDir = await storageDir.create(recursive: true);
      setState(() {
        start = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () => setState(() {
            metatron = createMetatron();
            run = !run;
          }),
          child: Icon((run) ? Icons.stop : Icons.play_arrow)),
      body: Center(
          child: Column(children: <Widget>[
            (start)
                ? Expanded(
                child:
                // [1] AnimatedDrawing.svg
                // AnimatedDrawing.svg(
                //   "assets/circle.svg",
                // [2] AnimatedDrawing.paths
                AnimatedDrawing.paths(
                  metatron,
                  paints: List<Paint>.generate(metatron.length, colorize),
                  run: run,
                  duration: Duration(seconds: 1),
                  lineAnimation: LineAnimation.oneByOne,
                  animationCurve: Curves.linear,
                  onFinish: () => setState(() {
                    run = false;
                  }),
                  //Uncomment this to write each frame to file
                  // debug: DebugOptions(
                  //   fileName: this.projectName,
                  //   showBoundingBox: false,
                  //   showViewPort: false,
                  //   recordFrames: true,
                  //   resolutionFactor: 2.0,
                  //   outPutDir: this.storageDir.path,
                  // ),
                ))
                : Container(),
          ])),
    );
  }

  //Here starts the Metatron-------------------------------
  final double r = 2;
  late List<Path> metatron;
  Grid g = Grid();

  Path circle(Offset offset) {
    return Path()..addOval(Rect.fromCircle(center: offset, radius: r));
  }

  Path rect(Offset offset) {
    return Path()..addRect(Rect.fromCircle(center: offset, radius: r / 4));
  }

  Path line(Offset a, Offset b) {
    return Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
  }

  Path arc(Offset a, Offset b) {
    return Path()
      ..moveTo(a.dx, a.dy)
      ..arcToPoint(b, radius: Radius.circular(r));
    // return Path()..moveTo(a.dx,a.dy)..conicTo(cp.dx,cp.dy,b.dx,b.dy,1);
  }

  Path center(Offset a, Offset b) {
    var cp = Offset.lerp(a, b, 0.5);
    return line(cp!, g[2][2]);
  }

  Path rotate(Path p, double radians) {
    var center = p.getBounds().center;
    var pp = p.transform(Matrix4.rotationZ(radians).storage);
    var offset = center - pp.getBounds().center;
    return pp.shift(offset);
  }

  Path out(Offset a) {
    var cp = Offset.lerp(g[2][2], a,
        3 / 4); //TODO make it so only depends on r - no hardcoded values
    return line(g[2][2], cp!);
  }

  Path spiral() {
    var p = Path();
    double angle, x, y;
    for (var i = 0; i < 299; i++) {
      angle = 0.1 * i;
      x = (1 + angle) * cos(angle);
      y = (1 + angle) * sin(angle);
      p.lineTo(x, y);
    }
    var factor =
        circle(g[2][2]).getBounds().longestSide / p.getBounds().longestSide;
    return p
        .transform(Matrix4.diagonal3Values(factor, factor, 0).storage)
        .shift(g[2][2]);
  }

  Paint colorize(int index) {
    //Main colors
    Color primaryColor = Colors.blueAccent;
    Color secondaryColor = Colors.orangeAccent;
    Color doodleColor = Colors.grey;
    //Theme Flutter:
    // Color primaryColor = Colors.blue[600];
    // Color secondaryColor = Colors.yellow[700];
    // Color doodleColor = Colors.grey[300];

    //Shaders
    var t = 5 * r;
    var grad = ui.Gradient.radial(g[2][2], t, [doodleColor, secondaryColor],
        [3.0 * r / t, 4 * r / t], TileMode.mirror);

    //Gray circles
    if (index <= 5) {
      return Paint()
        ..style = PaintingStyle.stroke
        ..color = doodleColor
        ..strokeWidth = 0.2
        ..strokeCap = StrokeCap.round;
    }

    //Gray triangles
    if (index >= 6 && index <= 11) {
      return Paint()
        ..style = PaintingStyle.stroke
        ..shader = grad
        ..color = doodleColor
        ..strokeWidth = 0.2
        ..strokeCap = StrokeCap.round;
    }

    //Outer conn.
    if (index >= 12 && index <= 17) {
      return Paint()
        ..style = PaintingStyle.stroke
        ..color = secondaryColor
        ..strokeWidth = 0.2
        ..strokeCap = StrokeCap.round;
    }

    //Center of inner circles
    if (index >= 18 && index <= 23) {
      return Paint()
        ..style = PaintingStyle.fill
        ..color = secondaryColor
        ..strokeWidth = 0.2
        ..strokeCap = StrokeCap.round;
    }

    //Inner spiral
    if (index == 24) {
      return Paint()
        ..style = PaintingStyle.stroke
        ..color = primaryColor
        ..strokeWidth = 0.2
        ..strokeCap = StrokeCap.round;
    }

    //Outer circles with connection to center
    if (index >= 25 && index <= 36) {
      return Paint()
        ..style = PaintingStyle.stroke
        ..color = primaryColor
        ..strokeWidth = 0.2
        ..strokeCap = StrokeCap.round;
    }

    if (index == 37) {
      return Paint()
        ..style = PaintingStyle.stroke
        ..color = primaryColor
        ..strokeWidth = 0.2
        ..strokeCap = StrokeCap.square;
    }

    //Default
    return Paint()
      ..style = PaintingStyle.stroke
      ..color = primaryColor
      ..strokeWidth = 0.2
      ..strokeCap = StrokeCap.round;
  }

  List<Path> createMetatron() {
    var paths = <Path>[];

    //Inner circles 0 - 5
    paths
      ..add(circle(g[2][1]))
      ..add(circle(g[1][1.5]))
      ..add(circle(g[3][1.5]))
      ..add(circle(g[1][2.5]))
      ..add(circle(g[2][3]))
      ..add(circle(g[3][2.5]));

    //Lines for background triangles: 6 - 11
    paths
      ..add(line(g[2][0], g[0][3]))
      ..add(line(g[2][0], g[4][3]))
      ..add(line(g[4][3], g[0][3]))
      ..add(line(g[0][1], g[4][1]))
      ..add(line(g[4][1], g[2][4]))
      ..add(line(g[2][4], g[0][1]));

    //Connect outer circles: 12-17
    paths
      ..add(line(g[2][0], g[0][1]))
      ..add(line(g[0][1], g[0][3]))
      ..add(line(g[0][3], g[2][4]))
      ..add(line(g[2][4], g[4][3]))
      ..add(line(g[4][3], g[4][1]))
      ..add(line(g[4][1], g[2][0]));

    //Center rectangle of outer circles 18-23
    paths
      ..add(rect(g[2][0]))
      ..add(rect(g[0][1]))
      ..add(rect(g[0][3]))
      ..add(rect(g[2][4]))
      ..add(rect(g[4][3]))
      ..add(rect(g[4][1]));

    //center spiral: 24
    paths.add(spiral());

    //Outer circles: 25-30  (rotated, so line terminate at same location as corresponding lines below)
    paths
      ..add(rotate(circle(g[2][0]), pi / 2))
      ..add(rotate(circle(g[0][1]), pi / 8))
      ..add(rotate(circle(g[0][3]), -pi / 4 + pi / 8))
      ..add(rotate(circle(g[2][4]), -pi / 2))
      ..add(rotate(circle(g[4][3]), pi + pi / 8))
      ..add(rotate(circle(g[4][1]), pi / 2 + pi / 4 + pi / 8));

    //Lines from center to outer circles: 31-36
    paths
      ..add(out(g[0][1]))
      ..add(out(g[0][3]))
      ..add(out(g[2][4]))
      ..add(out(g[4][3]))
      ..add(out(g[4][1]))
      ..add(out(g[2][0]));

    //Connect inner circles: 37
    paths.add(Path()
      ..addPolygon([
        g[2][1],
        g[1][1.5],
        g[1][2.5],
        g[2][3],
        g[3][2.5],
        g[3][1.5],
      ], true));

    return paths;
  }
}

//Wraps a grid function in a class so I can use the 2D array syntax, but with doubles
class Grid {
  Row operator [](num i) => Row(i.toDouble()); // get
}

class Row {
  const Row(this.row);
  final double row;
  Offset operator [](num col) => _g(row, col.toDouble());

  //Defines the grid
  Offset _g(double x, double y) {
    var r = 2;
    var d = r * 2;
    return Offset.zero.translate(x * d, y * d);
  }
}
