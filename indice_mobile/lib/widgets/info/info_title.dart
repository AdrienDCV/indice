import 'package:flutter/material.dart';

import 'info_tooltip_button.dart';

class InfoTitle extends StatelessWidget {
  const InfoTitle({super.key, required this.title, this.infoText});

  final String title;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final infoText = this.infoText;

    return Row(
      children: [
        Flexible(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (infoText != null) InfoTooltipButton(title: title, text: infoText),
      ],
    );
  }
}
