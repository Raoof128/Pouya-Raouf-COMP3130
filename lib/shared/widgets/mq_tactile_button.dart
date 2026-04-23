import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_animations.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/core/utils/haptics.dart';

/// Reusable tactile wrapper that adds:
/// - squishy press-in scale animation
/// - optional haptic tap feedback
/// - subtle resting drop shadow
class MqTactileButton extends StatefulWidget {
  const MqTactileButton({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = MqSpacing.radiusXl,
    this.hapticsEnabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final bool hapticsEnabled;

  @override
  State<MqTactileButton> createState() => _MqTactileButtonState();
}

class _MqTactileButtonState extends State<MqTactileButton> {
  bool _isPressed = false;

  void _handleTapCancel() {
    if (!mounted) return;
    setState(() => _isPressed = false);
  }

  void _handleTapDown(TapDownDetails details) {
    if (!mounted) return;
    setState(() => _isPressed = true);
    MqHaptics.light(widget.hapticsEnabled);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!mounted) return;
    setState(() => _isPressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapCancel: _handleTapCancel,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: MqAnimations.fast,
        curve: Curves.easeInOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              if (!_isPressed)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
