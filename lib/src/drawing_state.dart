import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'abstract_drawing_state.dart';
import 'drawing_widget.dart';

/// A state implementation which allows controlling the animation through an animation controller when provided.
class AnimatedDrawingState extends AbstractAnimatedDrawingState {
  AnimatedDrawingState() : super() {
    this.onFinishAnimation = () {
      if (!this.onFinishEvoked) {
        this.onFinishEvoked = true;
        SchedulerBinding.instance!.addPostFrameCallback((_) {
          this.onFinishAnimationDefault();
        });
      }
    };
  }

  @override
  void initState() {
    super.initState();
    this.controller = this.widget.controller;
    addListenersToAnimationController();
  }

  @override
  void didUpdateWidget(AnimatedDrawing oldWidget) {
    super.didUpdateWidget(oldWidget);
    this.controller = this.widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    return createCustomPaint(context);
  }
}
