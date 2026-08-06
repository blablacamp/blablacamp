import 'package:flutter/widgets.dart';

/// The signature asymmetric "leaf" corner used across Blablacamp cards/buttons:
/// large top-left & bottom-right, small top-right & bottom-left.
abstract final class AppShapes {
  static const double _large = 24;
  static const double _small = 8;

  static const BorderRadius leaf = BorderRadius.only(
    topLeft: Radius.circular(_large),
    topRight: Radius.circular(_small),
    bottomRight: Radius.circular(_large),
    bottomLeft: Radius.circular(_small),
  );

  static BorderRadius leafOf(double large, double small) => BorderRadius.only(
        topLeft: Radius.circular(large),
        topRight: Radius.circular(small),
        bottomRight: Radius.circular(large),
        bottomLeft: Radius.circular(small),
      );
}
