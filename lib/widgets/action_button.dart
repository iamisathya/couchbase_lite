import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const ActionButton({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final button = isOutlined ? _buildOutlinedButton(context) : _buildElevatedButton(context);
    
    return SizedBox(
      width: width,
      child: button,
    );
  }

  Widget _buildElevatedButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Icon(
              icon,
              color: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
      label: Text(
        isLoading ? 'Loading...' : text,
        style: TextStyle(
          color: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context) {
    final color = foregroundColor ?? Theme.of(context).colorScheme.primary;
    
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          : Icon(
              icon,
              color: color,
            ),
      label: Text(
        isLoading ? 'Loading...' : text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class CustomFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomFloatingActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
      child: Icon(icon),
    );
  }
}

class IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final bool isLoading;

  const IconActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.size = 24,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      icon: isLoading
          ? SizedBox(
              width: size * 0.8,
              height: size * 0.8,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : Icon(
              icon,
              color: color,
              size: size,
            ),
    );
  }
}

class ButtonRow extends StatelessWidget {
  final List<Widget> buttons;
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;

  const ButtonRow({
    super.key,
    required this.buttons,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: buttons
          .expand((button) => [button, SizedBox(width: spacing)])
          .toList()
          ..removeLast(), // Remove the last spacing
    );
  }
}

class ButtonColumn extends StatelessWidget {
  final List<Widget> buttons;
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;

  const ButtonColumn({
    super.key,
    required this.buttons,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      children: buttons
          .expand((button) => [button, SizedBox(height: spacing)])
          .toList()
          ..removeLast(), // Remove the last spacing
    );
  }
}