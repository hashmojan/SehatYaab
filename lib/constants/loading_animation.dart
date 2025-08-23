
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InfinityAnimation extends StatefulWidget {
  @override
  _InfinityAnimationState createState() => _InfinityAnimationState();
}

class _InfinityAnimationState extends State<InfinityAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: InfinityPainter(_controller),
      size: Size(200, 100),
    );
  }
}

class InfinityPainter extends CustomPainter {
  final Animation<double> animation;
  InfinityPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final halfHeight = height / 2;
    final quarterWidth = width / 4;

    // Create the infinity path
    path.moveTo(quarterWidth, halfHeight);
    path.cubicTo(quarterWidth * 1.5, 0, quarterWidth * 2.5, 0, quarterWidth * 3, halfHeight);
    path.cubicTo(quarterWidth * 2.5, height, quarterWidth * 1.5, height, quarterWidth, halfHeight);

    // Draw the track
    paint.color = Colors.black.withOpacity(0.1);
    canvas.drawPath(path, paint);

    // Draw the moving car
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final length = metric.length;
      final start = length * animation.value;
      final end = start + 10;
      paint.color = Colors.black;
      canvas.drawPath(metric.extractPath(start, end), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

//
// class TailChaseAnimation extends StatefulWidget {
//   final double size;
//   final Color color;
//   final double speed;
//
//   TailChaseAnimation({this.size = 40.0, this.color = Colors.black, this.speed = 1.75});
//
//   @override
//   _TailChaseAnimationState createState() => _TailChaseAnimationState();
// }
//
// class _TailChaseAnimationState extends State<TailChaseAnimation> with TickerProviderStateMixin {
//   late AnimationController _rotationController;
//   late List<AnimationController> _dotControllers;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _rotationController = AnimationController(
//       duration: Duration(milliseconds: (widget.speed * 1800).round()),
//       vsync: this,
//     )..repeat();
//
//     _dotControllers = List.generate(6, (index) {
//       return AnimationController(
//         duration: Duration(milliseconds: (widget.speed * 1000).round()),
//         vsync: this,
//       )..repeat(
//         reverse: false,
//         period: Duration(milliseconds: (widget.speed * 1000).round() - (index * 100)),
//       );
//     });
//   }
//
//   @override
//   void dispose() {
//     _rotationController.dispose();
//     _dotControllers.forEach((controller) => controller.dispose());
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: widget.size,
//       height: widget.size,
//       child: RotationTransition(
//         turns: _rotationController,
//         child: Stack(
//           children: List.generate(6, (index) {
//             final curvedAnimation = CurvedAnimation(
//               parent: _dotControllers[index],
//               curve: Curves.easeInOut, // Apply curve here
//             );
//
//             return AnimatedBuilder(
//               animation: curvedAnimation,
//               builder: (context, child) {
//                 double angle = curvedAnimation.value * 2.0 * math.pi;
//                 double radius = widget.size * 0.5;
//
//                 return Transform.translate(
//                   offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
//                   child: Transform.rotate(
//                     angle: angle,
//                     child: Align(
//                       alignment: Alignment.topCenter,
//                       child: Container(
//                         width: widget.size * 0.17,
//                         height: widget.size * 0.17,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: widget.color,
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );
//           }),
//         ),
//       ),
//     );
//   }
// }
