import 'package:flutter/material.dart';

enum AppLogoVariant {
  /// Full logo with suitcase illustration and "TapItTrip" wordmark.
  full,

  /// Suitcase icon mark only (for app bars, small chips, avatars).
  iconOnly,
}

/// Official brand logo widget for TapItTrip.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 96,
    this.width,
    this.variant = AppLogoVariant.full,
    this.borderRadius = 16.0,
    this.withCard = false,
  });

  /// Height of the logo in logical pixels.
  final double height;

  /// Width of the logo in logical pixels (null to scale proportionally).
  final double? width;

  /// Full logo or icon only variant.
  final AppLogoVariant variant;

  /// Corner radius when displayed in a card or clipped.
  final double borderRadius;

  /// Wrap the logo in a soft elevated/bordered squircle card.
  final bool withCard;

  @override
  Widget build(BuildContext context) {
    final assetPath = variant == AppLogoVariant.iconOnly
        ? 'assets/images/logo_icon.png'
        : 'assets/images/logo.png';

    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        assetPath,
        height: height,
        width: width ?? height,
        fit: BoxFit.contain,
        semanticLabel: 'TapItTrip Logo',
        errorBuilder: (context, error, stackTrace) {
          // Graceful fallback if asset cannot be loaded (e.g. headless unit tests)
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            height: height,
            width: width ?? height,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(
              Icons.luggage_rounded,
              size: height * 0.5,
              color: colorScheme.primary,
            ),
          );
        },
      ),
    );

    if (withCard) {
      final theme = Theme.of(context);
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius + 4),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: image,
      );
    }

    return image;
  }
}
