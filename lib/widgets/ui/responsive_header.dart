import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Responsive header converted from the React version.
/// Works on Web, iPhone (all), and Android with adaptive layout.
///
/// API parity with the original:
/// - [activeTab] : 'home' | 'trending'
/// - [onTabChange(String)]
/// - [onSearch(String)] (fires on every text change)
class WearHeader extends StatefulWidget implements PreferredSizeWidget {
  const WearHeader({
    super.key,
    required this.activeTab,
    required this.onTabChange,
    required this.onSearch,
    this.showAddAndUserIcons = true,
  });

  final String activeTab;
  final ValueChanged<String> onTabChange;
  final ValueChanged<String> onSearch;
  final bool showAddAndUserIcons;

  /// A safe constant height that fits two rows (toolbar + tab row) across devices.
  /// If you want this to be tighter, change to 96.
  @override
  Size get preferredSize => const Size.fromHeight(108);

  @override
  State<WearHeader> createState() => _WearHeaderState();
}

class _WearHeaderState extends State<WearHeader> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = MediaQuery.of(context).size.width;

    // Tailwind-like breakpoints (approx): sm=640, lg=1024
    final bool isSmUp = w >= 640; // show some desktop elements
    final bool isLgUp = w >= 1024; // allow wider content and search box

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold accent line
            SizedBox(
              height: 4,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF59E0B), // amber-500
                      Color(0xFFEAB308), // yellow-500
                      Color(0xFFF59E0B),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Top row
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isLgUp ? 1200 : (isSmUp ? 1000 : w)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isLgUp ? 24 : 16, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo + Title
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)], // blue-600 to indigo-600
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text('W', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                          if (isSmUp) ...[
                            const SizedBox(width: 8),
                            Text(
                              'MEN WEAR',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(width: 12),

                      // Search (center, max width)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: isLgUp ? 480 : 420),
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 36),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: widget.onSearch,
                                    textInputAction: TextInputAction.search,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: '搜尋穿搭、品牌、用戶...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  left: 10,
                                  child: Icon(Icons.search, size: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Right-side icons (hidden on extra small)
                      if (widget.showAddAndUserIcons && isSmUp) ...[
                        IconButton(
                          tooltip: '新增穿搭',
                          onPressed: () {},
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        IconButton(
                          tooltip: '個人',
                          onPressed: () {},
                          icon: const Icon(Icons.person_outline),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Bottom tabs
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isLgUp ? 1200 : (isSmUp ? 1000 : w)),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(isLgUp ? 24 : 16, 0, isLgUp ? 24 : 16, 8),
                  child: Row(
                    children: [
                      _TabButton(
                        active: widget.activeTab == 'home',
                        icon: Icons.home_outlined,
                        label: '首頁',
                        onTap: () => widget.onTabChange('home'),
                        showLabel: isSmUp,
                      ),
                      const SizedBox(width: 8),
                      _TabButton(
                        active: widget.activeTab == 'trending',
                        icon: Icons.trending_up,
                        label: '熱門',
                        onTap: () => widget.onTabChange('trending'),
                        showLabel: isSmUp,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Divider like border-b
            Divider(height: 1, thickness: 1, color: theme.dividerColor.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.showLabel,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final Color bg = active ? cs.primary : Colors.transparent;
    final Color fg = active ? cs.onPrimary : theme.textTheme.bodyMedium?.color ?? Colors.black87;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
