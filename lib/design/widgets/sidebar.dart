import 'package:flutter/material.dart';
import '../tokens.dart';

enum RpmDestination {
  overview('Overview', Icons.grid_view_outlined),
  transactions('Transactions', Icons.format_list_bulleted),
  mwk('MWK Ledger', Icons.menu_book_outlined),
  usd('USD Ledger', Icons.menu_book_outlined),
  categories('Categories', Icons.category_outlined),
  reports('Reports', Icons.description_outlined),
  backup('Backup & Restore', Icons.save_outlined),
  settings('Settings', Icons.info_outline);

  final String label;
  final IconData icon;
  const RpmDestination(this.label, this.icon);
}

class RpmSidebar extends StatelessWidget {
  final RpmDestination selected;
  final bool collapsed;
  final ValueChanged<RpmDestination> onSelected;
  final VoidCallback onToggle;
  const RpmSidebar({
    super.key,
    required this.selected,
    required this.collapsed,
    required this.onSelected,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    final p = context.rpm;
    final width = collapsed ? RpmTokens.collapsedWidth : RpmTokens.sidebarWidth;
    return AnimatedContainer(
      key: const Key('rpm-sidebar'),
      width: width,
      duration: RpmTokens.collapseDuration,
      curve: Curves.easeInOutCubic,
      color: p.sidebar,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: width,
          maxWidth: width,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(collapsed ? 20 : 16, 16, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: RpmTokens.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          size: 19,
                          color: RpmTokens.text,
                        ),
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 12),
                        Text(
                          'RPM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: p.text,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: collapsed ? 20 : 16,
                  ),
                  child: Text(
                    collapsed ? 'RPM' : 'RECEIPTS & PAYMENTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: p.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: collapsed ? 12 : 16,
                    ),
                    child: Column(
                      children: [
                        for (final destination in RpmDestination.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _SidebarItem(
                              destination: destination,
                              selected: selected == destination,
                              collapsed: collapsed,
                              onTap: () => onSelected(destination),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(collapsed ? 31 : 16, 16, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Offline · local storage',
                          style: TextStyle(fontSize: 12, color: p.success),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Tooltip(
                    message: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                    child: TextButton(
                      key: const Key('sidebar-toggle'),
                      onPressed: onToggle,
                      style: TextButton.styleFrom(
                        foregroundColor: p.secondary,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: collapsed
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          AnimatedRotation(
                            turns: collapsed ? -.25 : 0,
                            duration: RpmTokens.collapseDuration,
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                            ),
                          ),
                          if (!collapsed) ...[
                            const SizedBox(width: 12),
                            const Text(
                              'Collapse sidebar',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final RpmDestination destination;
  final bool selected, collapsed;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final p = context.rpm;
    final button = SizedBox(
      height: 40,
      child: TextButton(
        onPressed: onTap,
        style: ButtonStyle(
          animationDuration: RpmTokens.hoverDuration,
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => selected || s.contains(WidgetState.hovered)
                ? p.text
                : p.secondary,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => selected
                ? p.selected
                : s.contains(WidgetState.pressed)
                ? p.selected
                : s.contains(WidgetState.hovered)
                ? p.hover
                : Colors.transparent,
          ),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.focused)
                  ? p.accent
                  : Colors.transparent,
              width: 2,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        child: Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              destination.icon,
              size: 18,
              color: selected && collapsed ? p.accent : p.secondary,
            ),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      selected: selected,
      label: collapsed ? destination.label : null,
      child: collapsed
          ? Tooltip(message: destination.label, child: button)
          : button,
    );
  }
}
