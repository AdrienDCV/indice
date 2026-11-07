import 'package:flutter/material.dart';

class FavouriteIcon extends StatefulWidget {
  const FavouriteIcon({super.key, required this.isFavourite, this.color});

  final bool isFavourite;
  final Color? color;

  @override
  State<FavouriteIcon> createState() => _FavouriteIconState();
}

class _FavouriteIconState extends State<FavouriteIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.3,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.3,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 1,
    ),
  ]).animate(_bounceController);

  @override
  void didUpdateWidget(FavouriteIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavourite != widget.isFavourite &&
        !MediaQuery.disableAnimationsOf(context)) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.isFavourite ? Icons.star : Icons.star_border,
        color: widget.color,
      ),
    );
  }
}
