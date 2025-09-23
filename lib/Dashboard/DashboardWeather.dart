


// Interactive Sun Path Widget
import 'package:cropai/Dashboard/Sunpath.dart';
import 'package:flutter/widgets.dart';


class InteractiveSunPath extends StatefulWidget {
  final double sunPosition;
  final Function(double) onSunPositionChanged;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;

  const InteractiveSunPath({
    super.key,
    required this.sunPosition,
    required this.onSunPositionChanged,
    required this.onInteractionStart,
    required this.onInteractionEnd,
  });

  @override
  _InteractiveSunPathState createState() => _InteractiveSunPathState();
}

class _InteractiveSunPathState extends State<InteractiveSunPath> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        widget.onInteractionStart();
        _handlePanUpdate(details.localPosition);
      },
      onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
      onPanEnd: (details) => widget.onInteractionEnd(),
      onTapDown: (details) {
        widget.onInteractionStart();
        _handlePanUpdate(details.localPosition);
      },
      onTapUp: (details) => widget.onInteractionEnd(),
      child: CustomPaint(
        painter: InteractiveSunPathPainter(
          sunPosition: widget.sunPosition,
        ),
        child: const SizedBox(
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  void _handlePanUpdate(Offset localPosition) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    // Convert touch position to sun position (0.0 to 1.0)
    double newPosition = (localPosition.dx / size.width).clamp(0.0, 1.0);

    widget.onSunPositionChanged(newPosition);
  }
}
