import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Card personalizada de S&G
///
/// Tipos disponibles:
/// - Elevated (con sombra)
/// - Filled (con color de fondo)
/// - Outlined (con borde)
///
/// Uso:
/// ```dart
/// CustomCard(
///   child: Text('Contenido'),
///   type: CardType.elevated,
/// )
/// ```
enum CardType { elevated, filled, outlined }

class CustomCard extends StatelessWidget {
  final Widget child;
  final CardType type;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const CustomCard({
    super.key,
    required this.child,
    this.type = CardType.elevated,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    Widget card;

    switch (type) {
      case CardType.elevated:
        card = Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: cardContent,
        );
        break;

      case CardType.filled:
        card = Card(
          elevation: 0,
          color: AppColors.backgroundGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: cardContent,
        );
        break;

      case CardType.outlined:
        card = Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: AppColors.border,
              width: 1.5,
            ),
          ),
          child: cardContent,
        );
        break;
    }

    if (onTap != null) {
      return Container(
        margin: margin,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }

    return Container(
      margin: margin,
      child: card,
    );
  }
}