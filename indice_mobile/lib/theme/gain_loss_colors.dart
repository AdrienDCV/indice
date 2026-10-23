import 'package:flutter/material.dart';

import '../utils/number_formatting.dart';

@immutable
class GainLossColors extends ThemeExtension<GainLossColors> {
  const GainLossColors({required this.gain, required this.loss});

  final Color gain;
  final Color loss;

  Color? colorOf(ValueTrend trend) => switch (trend) {
    ValueTrend.gain => gain,
    ValueTrend.loss => loss,
    ValueTrend.neutral => null,
  };

  @override
  GainLossColors copyWith({Color? gain, Color? loss}) {
    return GainLossColors(gain: gain ?? this.gain, loss: loss ?? this.loss);
  }

  @override
  GainLossColors lerp(GainLossColors? other, double t) {
    if (other == null) return this;
    return GainLossColors(
      gain: Color.lerp(gain, other.gain, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
    );
  }
}
