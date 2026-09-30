import 'package:flutter/material.dart';

/// The PrivateAgent mark: a simple solid black circle.
///
/// Renders the black-circle asset centered on a white circular tile. On
/// light surfaces the tile is invisible so only the circle shows; on the
/// black app bar (or dark surfaces) the tile keeps the mark visible.
class AppLogo extends StatelessWidget {
  /// Overall tile diameter in logical pixels.
  final double size;

  const AppLogo({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(size * 0.14),
        child: Image.asset(
          'assets/icon/genie_logo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
