import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Anchor Learning 的 3D 凸起主操作按钮。
class AnchorButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? darkColor;
  final bool enabled;
  final double? width;
  final double height;
  final IconData? icon;
  final double fontSize;

  const AnchorButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.green,
    this.darkColor,
    this.enabled = true,
    this.width,
    this.height = 48,
    this.icon,
    this.fontSize = 16,
  });

  @override
  State<AnchorButton> createState() => _AnchorButtonState();
}

class _AnchorButtonState extends State<AnchorButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final darkColor = widget.darkColor ?? _darken(widget.color);
    final isDisabled = !widget.enabled || widget.onPressed == null;

    final bgColor = isDisabled ? AppColors.textLight : widget.color;
    final borderColor = isDisabled ? AppColors.border : darkColor;

    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (!isDisabled) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(0, _isPressed ? 2.0 : 0, 0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: _isPressed ? 2 : 4,
            ),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _darken(Color color) {
    return color.withValues(
      red: color.r * 0.8,
      green: color.g * 0.8,
      blue: color.b * 0.8,
    );
  }
}
