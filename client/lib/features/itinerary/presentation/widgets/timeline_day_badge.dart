import 'package:flutter/material.dart';

class TimelineDayBadge extends StatelessWidget {
  const TimelineDayBadge({
    super.key,
    required this.dayNumber,
    this.isFirst = false,
    this.isLast = false,
  });

  final int dayNumber;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top vertical connector line
        Container(
          width: 2,
          height: isFirst ? 8 : 16,
          color: isFirst
              ? Colors.transparent
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        // Day circle badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$dayNumber',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        // Bottom vertical connector line
        Expanded(
          child: Container(
            width: 2,
            color: isLast
                ? Colors.transparent
                : colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
