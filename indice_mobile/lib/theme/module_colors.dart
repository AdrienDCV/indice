import 'package:flutter/material.dart';

@immutable
class ModuleColors extends ThemeExtension<ModuleColors> {
  const ModuleColors({required this.compare});

  final Color compare;

  @override
  ModuleColors copyWith({Color? compare}) {
    return ModuleColors(compare: compare ?? this.compare);
  }

  @override
  ModuleColors lerp(ModuleColors? other, double t) {
    if (other == null) return this;
    return ModuleColors(compare: Color.lerp(compare, other.compare, t)!);
  }
}
