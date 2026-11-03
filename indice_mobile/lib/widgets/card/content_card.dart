import 'package:flutter/material.dart';

import '../info/info_title.dart';

class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.title,
    required this.child,
    this.infoText,
  });

  final String title;
  final Widget child;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            InfoTitle(title: title, infoText: infoText),
            child,
          ],
        ),
      ),
    );
  }
}
