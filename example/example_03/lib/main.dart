import 'dart:async';
import 'dart:core';
import 'package:drawing_animation/drawing_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.title = ''}) : super(key: key);
  final String title;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  //name(0)  LineAnimation(1), animationCurve(2), duration(3), backgroundColor(4), isRepeat(5), PathOrder(6), web (7), title (8)
  List<List> assets = [
    //0
    [
      'head1',
      LineAnimation.oneByOne,
      Curves.linear,
      5,
      Colors.blue[400],
      false,
      PathOrders.original,
      'https://www.flickr.com/photos/britishlibrary/11004937825',
      'Welcome!'
    ],
    //1
    [
      'egypt1',
      LineAnimation.oneByOne,
      Curves.linear,
      5,
      const Color.fromRGBO(224, 121, 42, 1.0),
      false,
      PathOrders.original,
      'https://www.flickr.com/photos/britishlibrary/11009096375',
      'LineAnimation'
    ],
    //2
    [
      'child6',
      LineAnimation.oneByOne,
      Curves.linear,
      3,
      Colors.white,
      false,
      PathOrders.leftToRight,
      'https://www.flickr.com/photos/britishlibrary/11168330443/',
      'Animation order I - byPosition'
    ],
    //3
    [
      'child8',
      LineAnimation.oneByOne,
      Curves.linear,
      5,
      Colors.white,
      false,
      PathOrders.leftToRight,
      'https://www.flickr.com/photos/britishlibrary/11290437266',
      'Animation order II - byLength'
    ],
    //4
    [
      'dino2',
      LineAnimation.oneByOne,
      Curves.linear,
      5,
      Colors.black,
      false,
      PathOrders.original,
      'https://www.flickr.com/photos/britishlibrary/11300302103',
      'Curve I'
    ],
    //5
    [
      'child7',
      LineAnimation.oneByOne,
      Curves.linear,
      5,
      Colors.black,
      false,
      PathOrders.original,
      'https://www.flickr.com/photos/britishlibrary/11290437266',
      'Colors and more!'
    ],
  ];

  List<Curve> curves = [
    Curves.bounceIn,
    Curves.bounceInOut,
    Curves.bounceOut,
    Curves.decelerate,
    Curves.elasticIn,
    Curves.elasticInOut,
    Curves.elasticOut,
    Curves.linear
  ];

  List<List> paintOrderFunctions = [
    ['No sort', PathOrders.original],
    ['LeftToRight', PathOrders.leftToRight],
    ['RightToLeft', PathOrders.rightToLeft],
    ['TopToBottom', PathOrders.topToBottom],
    ['BottomToTop', PathOrders.bottomToTop],
    ['IncreasingLength', PathOrders.increasingLength],
    ['DecreasingLength', PathOrders.decreasingLength],
    [
      'LeftToRight x TopToBottom',
      PathOrders.leftToRight.combine(PathOrders.topToBottom)
    ],
  ];

  bool isRunning = false; //all drawings are paused in the beginning
  int previousScreen = 0;
  bool cardExpanded = false;
  bool showSwipe = false;
  bool showStartButton = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        itemBuilder: (context, position) {
          return createPage(position, context);
        },
        itemCount: assets.length,
      ),
    );
  }

  Widget createPage(int i, BuildContext context) {
    var isLandscape =
        (MediaQuery.of(context).orientation == Orientation.portrait);
    if (previousScreen != i) {
      isRunning = false;
      showStartButton = true;
      previousScreen = i;
    }

    return Stack(children: <Widget>[
      Container(
        color: assets[i][4] as Color,
      ),
      Column(children: <Widget>[
        (isLandscape) ? Expanded(flex: 3, child: Container()) : Container(),
        (isLandscape)
            ? Expanded(
                flex: 6,
                child: Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: createInstructions(i))))
            : Container(),
        Flexible(
            flex: 12,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(),
              child: Stack(children: <Widget>[
                (!isRunning && showStartButton)
                    ? Center(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                            Text(
                              'Start animation',
                              style: TextStyle(
                                color: (assets[i][4] == Colors.black)
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.touch_app,
                                color: (assets[i][4] == Colors.black)
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  startAnimation(i);
                                });
                              },
                            )
                          ]))
                    : Container(),
                GestureDetector(
                    onTap: () => startAnimation(i),
                    child: AnimatedDrawing.svg(
                      'assets/${assets[i][0]}.svg',
                      run: isRunning,
                      duration: Duration(seconds: assets[i][3] as int),
                      lineAnimation: assets[i][1] as LineAnimation,
                      animationCurve: assets[i][2] as Curve,
                      animationOrder: assets[i][6] as PathOrder,
                      onFinish: () {
                        setState(() {
                          if (assets[i][5] == false) {
                            //no-repeat
                            isRunning = false;
                            showStartButton = false;
                          }
                        });

                        if (i == 0) {
                          Timer(const Duration(seconds: 2), () {
                            setState(() {
                              showSwipe = true;
                            });
                          });
                        }
                      },
                    )),
                Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: (assets[i][4] == Colors.black)
                            ? Colors.white
                            : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          launchURL(i);
                        });
                      },
                    )),
              ]),
            )),
      ]),
      (isLandscape)
          ? Column(children: <Widget>[
              AnimatedSize(
                  curve: Curves.bounceInOut,
                  duration: const Duration(milliseconds: 800),
                  child: Card(
                      margin: const EdgeInsets.all(20.0),
                      color: Colors.grey[250],
                      child: Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(children: <Widget>[
                            Row(children: <Widget>[
                              Flexible(
                                  flex: 2,
                                  child: Column(
                                    children: createCardOptions(i),
                                  ))
                            ]),
                          ])))),
              Expanded(
                flex: 4,
                child: Container(),
              ) //TODO Fix, Find Expanded in the Card Widget tree
            ])
          : Container(),
    ]);
  }

  List<Widget> createCardOptions(int i) {
    var options = <Widget>[
      Row(children: <Widget>[
        (cardExpanded)
            ? const Expanded(
                flex: 1,
                child: Text('Asset: ',
                    style: TextStyle(fontWeight: FontWeight.bold)))
            : Text('${assets[i][8]}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
        (cardExpanded)
            ? Expanded(
                flex: 1,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${assets[i][0]}')))
            : Container(),
        Expanded(
            flex: 1,
            child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Control path animations',
                  onPressed: () {
                    setState(() {
                      cardExpanded = !cardExpanded;
                    });
                  },
                ))),
      ])
    ];

    if (cardExpanded) {
      options.addAll(<Widget>[
        Row(children: <Widget>[
          //LineAnimation
          Expanded(
              flex: 3,
              child: Row(children: <Widget>[
                const Expanded(
                    child: Text('LineAnimation:',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: ChoiceChip(
                  label: const Text('allAtOnce'),
                  selected: assets[i][1] == LineAnimation.allAtOnce,
                  onSelected: (bool selected) {
                    setState(() {
                      assets[i][1] = selected
                          ? LineAnimation.allAtOnce
                          : LineAnimation.oneByOne;
                    });
                  },
                )),
                Expanded(
                    child: ChoiceChip(
                  label: const Text('oneByOne'),
                  selected: assets[i][1] == LineAnimation.oneByOne,
                  onSelected: (bool selected) {
                    setState(() {
                      assets[i][1] = selected
                          ? LineAnimation.oneByOne
                          : LineAnimation.allAtOnce;
                    });
                  },
                )),
              ])),
        ]),
        Row(children: <Widget>[
          //LineAnimation
          Expanded(
              flex: 3,
              child: Row(children: <Widget>[
                const Expanded(
                    child: Text('Repeat:',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: ChoiceChip(
                  label: const Text('Once'),
                  selected: assets[i][5] == false,
                  onSelected: (bool selected) {
                    setState(() {
                      assets[i][5] = !selected;
                    });
                  },
                )),
                Expanded(
                    child: ChoiceChip(
                  label: const Text('Infinite'),
                  selected: assets[i][5] == true,
                  onSelected: (bool selected) {
                    setState(() {
                      assets[i][5] = selected;
                    });
                  },
                )),
              ])),
        ]),
        Row(children: <Widget>[
          const Expanded(
              flex: 1,
              child: Text('AnimationCurve: ',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DropdownButton<Curve>(
            value: assets[i][2] as Curve,
            onChanged: (Curve? curve) {
              setState(() {
                assets[i][2] = curve;
              });
            },
            items: curves.map((Curve curve) {
              return DropdownMenuItem<Curve>(
                value: curve,
                child: Text(
                  curve.runtimeType
                      .toString()
                      .substring(1)
                      .replaceAll(RegExp(r'Curve'), ''),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
          ),
        ]),
        Row(children: <Widget>[
          const Expanded(
              flex: 1,
              child: Text('PathOrder: ',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DropdownButton<PathOrder>(
            value: assets[i][6] as PathOrder,
            onChanged: (PathOrder? order) {
              setState(() {
                assets[i][6] = order;
              });
            },
            items: paintOrderFunctions.map((List orders) {
              return DropdownMenuItem<PathOrder>(
                value: orders[1] as PathOrder,
                child: Text(
                  '${orders[0]}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ]),
        Row(children: <Widget>[
          const Expanded(
            flex: 1,
            child: Text(
              'Duration: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Slider(
              activeColor: Colors.indigoAccent,
              min: 1,
              max: 15,
              divisions: 15,
              onChanged: (val) {
                setState(() => assets[i][3] = val.round());
              },
              value: double.parse(
                  assets[i][3].toString()), //assets[i][3].toDouble(),
            ),
          ),
        ]),
      ]);
    }
    return options;
  }

  Widget createInstructions(int i) {
    switch (i) {
      case 0:
        return wrap([
          const Expanded(
              child: Text(
                  'This is a simple application showcasing the capabilities of the `drawing_animation` package.')),
          (showSwipe && i == 0 && !isRunning) ? getSwipeWidget() : Container(),
        ]);
      case 1:
        return wrap([
          const Text(
              'Path elements are either drawn one after the other or all at once.'),
          Row(children: <Widget>[
            createChoiceChip(i, 1, 'oneByOne', LineAnimation.oneByOne),
            createChoiceChip(i, 1, 'allAtOnce', LineAnimation.allAtOnce)
          ])
        ]);
      case 2:
        return wrap([
          const Text(
              'The animation order defines which path segment is drawn first on the canvas.'),
          Row(children: <Widget>[
            createChoiceChip(i, 6, 'toRight', PathOrders.leftToRight),
            createChoiceChip(i, 6, 'toLeft', PathOrders.rightToLeft),
            createChoiceChip(i, 6, 'toBottom', PathOrders.topToBottom),
            createChoiceChip(i, 6, 'toTop', PathOrders.bottomToTop),
          ]),
        ]);
      case 3:
        return wrap([
          const Text(
              'A different animation order is e.g. obtained via the size of each element: '),
          Row(children: <Widget>[
            createChoiceChip(i, 6, 'toRight', PathOrders.leftToRight),
            createChoiceChip(i, 6, 'descreasing', PathOrders.decreasingLength),
            createChoiceChip(i, 6, 'increasing', PathOrders.increasingLength),
          ]),
        ]);
      case 4:
        return wrap([
          const Text(
              'Curves in Flutter are used to manipulate the change of an animation over time.'),
          Row(children: <Widget>[
            createChoiceChip(i, 2, 'linear', Curves.linear),
            createChoiceChip(i, 2, 'bounceInOut', Curves.bounceInOut),
          ]),
        ]);
      default:
        return const Text('Generic here...');
    }
  }

  Widget getSwipeWidget() {
    return Expanded(
        child: Container(
            padding: const EdgeInsets.all(1.0),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.arrow_back_ios),
                  Icon(Icons.arrow_back_ios),
                  Text('Swipe left!'),
                ])));
  }

  Widget createChoiceChip(int i, int j, String text, Object object) {
    return Expanded(
        child: ChoiceChip(
      label: Text(text),
      selected: assets[i][j] == object,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            //Restart animation - Pause
            isRunning = false;
            showStartButton = false;
          });

          Timer(const Duration(milliseconds: 10), () {
            setState(() {
              assets[i][j] = object;
              isRunning = true;
            });
          });
        }
      },
    ));
  }

  Widget createChoiceChipMulti(
      int i, List<int> jj, String text, List<Object> objects) {
    return Expanded(
        child: ChoiceChip(
      label: Text(text),
      selected: assets[i][jj.first] ==
          objects.first, //boolean depends on first object
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            //Restart animation - Pause
            isRunning = false;
            showStartButton = false;
          });

          Timer(const Duration(milliseconds: 10), () {
            setState(() {
              for (var m = 0; m < objects.length; m++) {
                assets[i][jj[m]] = objects[m];
              }
              isRunning = true;
            });
          });
        }
      },
    ));
  }

  Widget wrap(List<Widget> widgets) {
    return Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: Colors.white,
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widgets));
  }

  void launchURL(int i) async {
    var url = assets[i][7] as String;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void startAnimation(int i) {
    setState(() {
      isRunning = !isRunning;
    });
  }
}
