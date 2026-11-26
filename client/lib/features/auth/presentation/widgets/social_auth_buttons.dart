import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.isLoading,
    required this.onGooglePressed,
    required this.onFacebookPressed,
  });

  final bool isLoading;
  final VoidCallback onGooglePressed;
  final VoidCallback onFacebookPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or continue with',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: colorScheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: isLoading ? null : onGooglePressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerLowest,
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(color: colorScheme.outlineVariant),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GoogleLogoIcon(size: 20),
              SizedBox(width: 12),
              Text('Continue with Google'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: isLoading ? null : onFacebookPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerLowest,
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(color: colorScheme.outlineVariant),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FacebookLogoIcon(size: 20),
              SizedBox(width: 12),
              Text('Continue with Facebook'),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _GoogleLogoPainter()),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.21;
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // Red top-left to top-right arc
    canvas.drawArc(
      rect,
      -math.pi * 0.80,
      math.pi * 0.58,
      false,
      arcPaint(AppColors.googleRed),
    );
    // Yellow left arc
    canvas.drawArc(
      rect,
      math.pi * 0.78,
      math.pi * 0.44,
      false,
      arcPaint(AppColors.googleYellow),
    );
    // Green bottom arc
    canvas.drawArc(
      rect,
      math.pi * 0.20,
      math.pi * 0.60,
      false,
      arcPaint(AppColors.googleGreen),
    );
    // Blue right-bottom arc
    canvas.drawArc(
      rect,
      -math.pi * 0.04,
      math.pi * 0.28,
      false,
      arcPaint(AppColors.googleBlue),
    );

    // Blue horizontal crossbar of the "G"
    final barPaint = Paint()
      ..color = AppColors.googleBlue
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final barHeight = strokeWidth * 0.92;
    final barRect = Rect.fromLTWH(
      center.dx - size.width * 0.02,
      center.dy - barHeight / 2,
      size.width * 0.50,
      barHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(barHeight * 0.15)),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FacebookLogoIcon extends StatelessWidget {
  const _FacebookLogoIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _FacebookLogoPainter()),
      ),
    );
  }
}

class _FacebookLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Official Facebook blue circle
    final bgPaint = Paint()
      ..color = AppColors.facebookBlue
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, w / 2, bgPaint);

    // Crisp white lowercase "f" scaled from standard 24x24 Facebook mark
    final sx = w / 24.0;
    final sy = h / 24.0;
    final fPath = Path()
      ..moveTo(13.5 * sx, 23.8 * sy)
      ..lineTo(13.5 * sx, 14.5 * sy)
      ..lineTo(16.6 * sx, 14.5 * sy)
      ..lineTo(17.1 * sx, 10.9 * sy)
      ..lineTo(13.5 * sx, 10.9 * sy)
      ..lineTo(13.5 * sx, 8.6 * sy)
      ..cubicTo(
        13.5 * sx,
        7.55 * sy,
        13.8 * sx,
        6.85 * sy,
        15.3 * sx,
        6.85 * sy,
      )
      ..lineTo(17.2 * sx, 6.85 * sy)
      ..lineTo(17.2 * sx, 3.65 * sy)
      ..cubicTo(16.85 * sx, 3.6 * sy, 15.7 * sx, 3.5 * sy, 14.4 * sx, 3.5 * sy)
      ..cubicTo(11.65 * sx, 3.5 * sy, 9.8 * sx, 5.15 * sy, 9.8 * sx, 8.2 * sy)
      ..lineTo(9.8 * sx, 10.9 * sy)
      ..lineTo(6.7 * sx, 10.9 * sy)
      ..lineTo(6.7 * sx, 14.5 * sy)
      ..lineTo(9.8 * sx, 14.5 * sy)
      ..lineTo(9.8 * sx, 23.8 * sy)
      ..close();

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: w / 2)),
    );
    final fPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(fPath, fPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
