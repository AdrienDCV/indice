import 'package:flutter/widgets.dart';

EdgeInsets pagePadding(BuildContext context) {
  final insets = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(16, 16 + insets.top, 16, 16 + insets.bottom);
}
