import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 260);
  static const expressive = Duration(milliseconds: 420);

  static bool isReduced(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static Duration duration(BuildContext context, Duration duration) {
    return isReduced(context) ? Duration.zero : duration;
  }

  static Duration delay(BuildContext context, Duration delay) {
    return isReduced(context) ? Duration.zero : delay;
  }
}
