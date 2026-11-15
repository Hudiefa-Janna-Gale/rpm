import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens.dart';
import 'button.dart';

class RpmSurface extends StatelessWidget {
  final Widget child;
  final bool filled, outlined;
  final EdgeInsetsGeometry? padding;
  const RpmSurface({
    super.key,
    required this.child,
    this.filled = false,
    this.outlined = true,
    this.padding,
  });
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: filled ? context.rpm.card : context.rpm.sidebar,
      borderRadius: BorderRadius.circular(12),
      border: outlined ? Border.all(color: context.rpm.border) : null,
    ),
    padding: padding,
    child: child,
  );
}

class RpmPageHeader extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> actions;
  final VoidCallback? onRefresh;
  final bool refreshing;
  const RpmPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.onRefresh,
    this.refreshing = false,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final controls = [
        if (onRefresh != null)
          RpmButton(
            key: const ValueKey('refresh-records'),
            label: 'Refresh',
            icon: Icons.refresh,
            tooltip: 'Refresh saved records (Ctrl+R / ⌘R or F5)',
            loading: refreshing,
            onPressed: onRefresh,
          ),
        ...actions,
      ];
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.25,
              color: context.rpm.secondary,
            ),
          ),
        ],
      );
      if (constraints.maxWidth < 880 && controls.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            const SizedBox(height: 20),
            Wrap(spacing: 12, runSpacing: 12, children: controls),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: heading),
          if (controls.isNotEmpty) ...[
            const SizedBox(width: 24),
            Wrap(spacing: 12, children: controls),
          ],
        ],
      );
    },
  );
}

class RpmEmptyState extends StatelessWidget {
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const RpmEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(fontSize: 13, color: context.rpm.secondary),
          textAlign: TextAlign.center,
        ),
        if (onAction != null) ...[
          const SizedBox(height: 16),
          RpmButton(
            label: actionLabel ?? 'Add transaction',
            icon: Icons.add,
            variant: RpmButtonVariant.ghost,
            onPressed: onAction,
          ),
        ],
      ],
    ),
  );
}

class RpmBanner extends StatelessWidget {
  final String message;
  final bool error;
  const RpmBanner({super.key, required this.message, this.error = false});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: error ? context.rpm.dangerSurface : context.rpm.warningSurface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      message,
      style: TextStyle(
        fontSize: 12,
        color: error ? context.rpm.danger : context.rpm.warning,
      ),
    ),
  );
}

class RpmDialogFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final double width;
  const RpmDialogFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.actions,
    this.onClose,
    this.width = 560,
  });
  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () {
        if (onClose != null) {
          onClose!();
        } else {
          Navigator.maybePop(context);
        }
      },
    },
    child: Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (onClose != null)
                    RpmButton(
                      icon: Icons.close,
                      tooltip: 'Close dialog',
                      variant: RpmButtonVariant.ghost,
                      onPressed: onClose,
                    ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    color: context.rpm.secondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Flexible(child: SingleChildScrollView(child: child)),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
