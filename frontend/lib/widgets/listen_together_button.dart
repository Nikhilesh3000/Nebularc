import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ListenTogetherButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;

  const ListenTogetherButton({
    super.key,
    this.label = 'Listen Together',
    this.onPressed,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 18,
            vertical: compact ? 5 : 9,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.pink.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: compact ? 11 : 13),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}