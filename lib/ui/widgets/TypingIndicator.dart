import 'dart:math';
import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.bubbleColor = const Color(0xFF646b7f),
    this.flashingCircleDarkColor = const Color(0xFF333333),
    this.flashingCircleBrightColor = const Color(0xFFaec1dd),
  });

  final Color bubbleColor;
  final Color flashingCircleDarkColor;
  final Color flashingCircleBrightColor;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {

  late AnimationController _repeatingController;
  final List<Interval> _dotIntervals = const [
    Interval(0.25, 0.8),
    Interval(0.35, 0.9),
    Interval(0.45, 1.0),
  ];

  @override
  void initState() {
    super.initState();
    _repeatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _repeatingController.repeat();
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _repeatingController.repeat();
  }

  @override
  void dispose() {
    _repeatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatusBubble(
      repeatingController: _repeatingController,
      dotIntervals: _dotIntervals,
      flashingCircleDarkColor: widget.flashingCircleDarkColor,
      flashingCircleBrightColor: widget.flashingCircleBrightColor,
    );
  }
}

class CircleBubble extends StatelessWidget {
  const CircleBubble({
    super.key,
    required this.size,
    required this.bubbleColor,
  });

  final double size;
  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bubbleColor,
      ),
    );
  }
}

class AnimatedBubble extends StatelessWidget {
  const AnimatedBubble({
    super.key,
    required this.animation,
    required this.left,
    required this.bottom,
    required this.bubble,
  });

  final Animation<double> animation;
  final double left;
  final double bottom;
  final Widget bubble;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            alignment: Alignment.bottomLeft,
            child: child,
          );
        },
        child: bubble,
      ),
    );
  }
}

class StatusBubble extends StatelessWidget {
  const StatusBubble({
    super.key,
    required this.repeatingController,
    required this.dotIntervals,
    required this.flashingCircleBrightColor,
    required this.flashingCircleDarkColor,
  });

  final AnimationController repeatingController;
  final List<Interval> dotIntervals;
  final Color flashingCircleDarkColor;
  final Color flashingCircleBrightColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FlashingCircle(
          index: 0,
          repeatingController: repeatingController,
          dotIntervals: dotIntervals,
          flashingCircleDarkColor: flashingCircleDarkColor,
          flashingCircleBrightColor: flashingCircleBrightColor,
        ),
        FlashingCircle(
          index: 1,
          repeatingController: repeatingController,
          dotIntervals: dotIntervals,
          flashingCircleDarkColor: flashingCircleDarkColor,
          flashingCircleBrightColor: flashingCircleBrightColor,
        ),
        FlashingCircle(
          index: 2,
          repeatingController: repeatingController,
          dotIntervals: dotIntervals,
          flashingCircleDarkColor: flashingCircleDarkColor,
          flashingCircleBrightColor: flashingCircleBrightColor,
        ),
      ],
    );
  }
}

class FlashingCircle extends StatelessWidget {
  const FlashingCircle({
    super.key,
    required this.index,
    required this.repeatingController,
    required this.dotIntervals,
    required this.flashingCircleBrightColor,
    required this.flashingCircleDarkColor,
  });

  final int index;
  final AnimationController repeatingController;
  final List<Interval> dotIntervals;
  final Color flashingCircleDarkColor;
  final Color flashingCircleBrightColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: repeatingController,
      builder: (context, child) {
        final circleFlashPercent = dotIntervals[index].transform(
          repeatingController.value,
        );
        final circleColorPercent = sin(pi * circleFlashPercent);

        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              flashingCircleDarkColor,
              flashingCircleBrightColor,
              circleColorPercent,
            ),
          ),
        );
      },
    );
  }
}

class FakeMessage extends StatelessWidget {
  const FakeMessage({
    super.key,
    required this.isBig,
  });

  final bool isBig;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
      height: isBig ? 128.0 : 36.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: Colors.grey.shade300,
      ),
    );
  }
}