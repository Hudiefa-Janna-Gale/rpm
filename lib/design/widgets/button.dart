import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../tokens.dart';

enum RpmButtonVariant { primary, secondary, outline, ghost, danger, success }

class RpmButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool alignStart;
  final VoidCallback? onPressed;
  final RpmButtonVariant variant;
  final String? tooltip;
  final bool loading;
  final double? width;
  const RpmButton({
    super.key,
    this.label,
    this.icon,
    this.trailingIcon,
    this.alignStart = false,
    required this.onPressed,
    this.variant = RpmButtonVariant.outline,
    this.tooltip,
    this.loading = false,
    this.width,
  });
  @override
  State<RpmButton> createState() => _RpmButtonState();
}

class _RpmButtonState extends State<RpmButton> {
  final states = WidgetStatesController();
  @override
  void initState() {
    super.initState();
    states.addListener(update);
  }

  bool updateQueued = false;
  void update() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (updateQueued) return;
      updateQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateQueued = false;
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    states.removeListener(update);
    states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rpm;
    final enabled = widget.onPressed != null && !widget.loading;
    final focus = states.value.contains(WidgetState.focused);
    final hover = states.value.contains(WidgetState.hovered);
    final pressed = states.value.contains(WidgetState.pressed);
    final primary = widget.variant == RpmButtonVariant.primary;
    Color background = switch (widget.variant) {
      RpmButtonVariant.primary => RpmTokens.primary,
      RpmButtonVariant.secondary => p.card,
      RpmButtonVariant.danger => p.dangerSurface,
      RpmButtonVariant.success => p.success,
      _ => Colors.transparent,
    };
    Color foreground = switch (widget.variant) {
      RpmButtonVariant.primary => RpmTokens.text,
      RpmButtonVariant.danger => p.danger,
      RpmButtonVariant.success => RpmTokens.background,
      _ => p.text,
    };
    if (!enabled) {
      background = widget.variant == RpmButtonVariant.ghost
          ? Colors.transparent
          : p.card;
      foreground = p.secondary.withValues(alpha: .45);
    } else if (pressed) {
      background = p.selected;
    } else if (hover) {
      background = primary ? p.accent : p.hover;
    }
    final child = SizedBox(
      width: widget.width ?? (widget.label == null ? 40 : null),
      height: 40,
      child: AnimatedContainer(
        duration: pressed ? RpmTokens.pressDuration : RpmTokens.hoverDuration,
        decoration: BoxDecoration(
          color: primary && enabled && !hover && !pressed ? null : background,
          gradient: primary && enabled && !hover && !pressed
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [RpmTokens.primary, Color(0xFF4259E0)],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            width: focus ? 2 : 1,
            color: focus
                ? p.accent
                : widget.variant == RpmButtonVariant.outline
                ? p.border
                : primary && enabled
                ? p.accent.withValues(alpha: .5)
                : Colors.transparent,
          ),
        ),
        child: TextButton(
          statesController: states,
          onPressed: enabled ? widget.onPressed : null,
          style: ButtonStyle(
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: widget.label == null ? 0 : 16),
            ),
            minimumSize: const WidgetStatePropertyAll(Size.zero),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: WidgetStatePropertyAll(foreground),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            animationDuration: RpmTokens.hoverDuration,
            splashFactory: NoSplash.splashFactory,
            textStyle: const WidgetStatePropertyAll(
              TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.alignStart
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              if (widget.loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else if (widget.icon != null)
                Icon(widget.icon, size: 18),
              if (widget.label != null) ...[
                if (widget.icon != null || widget.loading)
                  const SizedBox(width: 8),
                if (widget.alignStart)
                  Expanded(
                    child: Text(
                      widget.label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      widget.label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(widget.trailingIcon, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
    return widget.tooltip == null
        ? child
        : Tooltip(message: widget.tooltip!, child: child);
  }
}
