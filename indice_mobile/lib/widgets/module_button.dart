import 'package:flutter/material.dart';

class ModuleButton extends StatefulWidget {
  const ModuleButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  State<ModuleButton> createState() => _ModuleButtonState();
}

/// Le bouton rétrécit quand on appuie, puis reprend sa taille
/// avant de déclencher [ModuleButton.onTap].
class _ModuleButtonState extends State<ModuleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 0.95,
  ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _pressController.forward();
    await _pressController.reverse();
    if (mounted) widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: widget.color ?? Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTapDown: (_) => _pressController.forward(),
          onTapCancel: _pressController.reverse,
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 45),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 45),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
