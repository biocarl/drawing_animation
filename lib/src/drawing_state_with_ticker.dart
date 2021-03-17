import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'abstract_drawing_state.dart';
import 'drawing_widget.dart';

/// A state implementation with an implemented animation controller to simplify the animation process
class AnimatedDrawingWithTickerState extends AbstractAnimatedDrawingState
    with SingleTickerProviderStateMixin {
  AnimatedDrawingWithTickerState() : super() {
    this.onFinishAnimation = () {
      if (!this.onFinishEvoked) {
        this.onFinishEvoked = true;
        SchedulerBinding.instance!.addPostFrameCallback((_) {
          this.onFinishAnimationDefault();
        });
        //Animation is completed when last frame is painted not when animation controller is finished
        if (this.controller!.status == AnimationStatus.dismissed ||
            this.controller!.status == AnimationStatus.completed) {
          this.finished = true;
        }
      }
    };
  }

  //Manage state
  bool paused = false;
  bool finished = true;

  @override
  void didUpdateWidget(AnimatedDrawing oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller!.duration = widget.duration;
  }

  @override
  void initState() {
    super.initState();
    controller = new AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    addListenersToAnimationController();
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    buildAnimation();
    return createCustomPaint(context);
  }

//
  Future<void> buildAnimation() async {
    try {
      if ((this.paused ||
              (this.finished &&
                  !(this.controller!.status == AnimationStatus.forward))) &&
          this.widget.run == true) {
        this.paused = false;
        this.finished = false;
        this.controller!.reset();
        this.onFinishEvoked = false;
        this.controller!.forward();
      } else if ((this.controller!.status == AnimationStatus.forward) &&
          this.widget.run == false) {
        this.controller!.stop();
        this.paused = true;
      }
    } on TickerCanceled {
      // TODO usecase?
    }
  }
}
