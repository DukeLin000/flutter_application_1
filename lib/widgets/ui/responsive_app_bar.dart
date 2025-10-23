import 'package:flutter/material.dart';

/// Responsive App Bar (Web / iOS / Android)
/// -------------------------------------------------------------
/// Usage:
///   Scaffold(
///     appBar: WearAppBar(
///       title: '衣櫃管理',
///       showSearch: true,
///       showSettings: true,
///       showAddButton: true,
///       onSearchClick: () {},
///       onSettingsClick: () {},
///       onAddClick: () {},
///     ),
///     body: ...,
///   );
class WearAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WearAppBar({
    super.key,
    required this.title,
    this.showSearch = false,
    this.showSettings = true,
    this.showAddButton = false,
    this.onSearchClick,
    this.onSettingsClick,
    this.onAddClick,
  });

  final String title;
  final bool showSearch;
  final bool showSettings;
  final bool showAddButton;
  final VoidCallback? onSearchClick;
  final VoidCallback? onSettingsClick;
  final VoidCallback? onAddClick;

  static bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final theme = Theme.of(context);

    return Material(
      elevation: 0,
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 金色重點線在最上方
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFBBF24), // amber-400
                    Color(0xFFF59E0B), // yellow-500-ish
                    Color(0xFFFBBF24),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // 主要列
            Container(
              height: kToolbarHeight,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // 左側：行動版 Logo
                        if (isMobile)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              alignment: Alignment.center,
                              child: const Text('W',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),

                        // 標題（在桌面與行動都顯示）
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),

                        // 桌面搜尋框
                        if (showSearch && !isMobile) ...[
                          const SizedBox(width: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: _SearchField(onTapSuffix: onSearchClick),
                          ),
                        ],

                        const Spacer(),

                        // 右側按鈕群
                        if (showAddButton)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilledButton.icon(
                              onPressed: onAddClick,
                              icon: const Icon(Icons.add, size: 20),
                              label: isMobile
                                  ? const SizedBox.shrink()
                                  : const Text('新增穿搭'),
                              style: isMobile
                                  ? FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      minimumSize: const Size(40, 40),
                                    )
                                  : null,
                            ),
                          ),

                        if (showSearch && isMobile)
                          IconButton(
                            tooltip: '搜尋',
                            onPressed: onSearchClick,
                            icon: const Icon(Icons.search),
                          ),
                        IconButton(
                          tooltip: '通知',
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_none),
                        ),
                        if (showSettings)
                          IconButton(
                            tooltip: '設定',
                            onPressed: onSettingsClick,
                            icon: const Icon(Icons.settings_outlined),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({this.onTapSuffix});
  final VoidCallback? onTapSuffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: TextField(
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: IconButton(
            onPressed: onTapSuffix,
            icon: const Icon(Icons.tune, size: 20),
            tooltip: '進階搜尋',
          ),
          hintText: '搜尋穿搭、品牌、用戶…',
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
