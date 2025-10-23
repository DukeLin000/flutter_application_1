import 'package:flutter/material.dart';

/// Simple mock outfit model (mirrors your mockOutfits intent)
class Outfit {
  final String id;
  final String title;
  final String subtitle; // e.g. weather, temp
  final List<String> tags; // e.g. style chips
  Outfit({required this.id, required this.title, required this.subtitle, this.tags = const []});
}

/// Demo data (replace with your real mockOutfits)
final List<Outfit> mockOutfits = [
  Outfit(id: 'o1', title: '機能外套 + 寬版褲', subtitle: '18°·微風', tags: ['戶外', '防潑水']),
  Outfit(id: 'o2', title: '針織衫 + 直筒褲', subtitle: '21°·舒適', tags: ['上班族', '休閒']),
  Outfit(id: 'o3', title: '連帽T + 工裝褲', subtitle: '16°·偶陣雨', tags: ['街頭', '保暖']),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.hasItems, required this.onAddItems});

  final bool hasItems;
  final VoidCallback onAddItems;

  // ----- RWD helpers -------------------------------------------------------
  double _containerMaxWidth(double w) {
    if (w >= 1600) return 1400; // very wide desktop
    if (w >= 1200) return 1200; // desktop
    if (w >= 900) return 980;   // tablets / large phones landscape
    if (w >= 600) return 760;   // small tablets / phones landscape
    return w - 24;              // phones portrait: leave gutters
  }

  int _gridCols(double w) {
    if (w >= 1200) return 3; // lg
    if (w >= 900) return 2;  // md
    return 1;                // sm
  }

  bool _isLarge(double w) => w >= 1200;

  // ----- Snack helpers (cross-platform toasts) ----------------------------
  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _handleSave(BuildContext ctx, String id) => _snack(ctx, '穿搭已儲存到收藏');
  void _handleShare(BuildContext ctx, String id) => _snack(ctx, '穿搭分享連結已複製');
  void _handleRefresh(BuildContext ctx) => _snack(ctx, '正在重新生成穿搭建議...');

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isLarge = _isLarge(w);

    if (!hasItems) {
      return Scaffold(
        appBar: AppBar(title: const Text('每日出裝'), actions: const [_SettingsButton()]),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(isLarge ? 24 : 16, 16, isLarge ? 24 : 16, isLarge ? 24 : 88),
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: '尚未建立衣櫃',
                description: '新增衣服單品，開始使用 AI 智能穿搭功能',
                actionLabel: '前往衣櫃',
                onAction: onAddItems,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日穿搭建議'),
        actions: [
          if (!isLarge)
            IconButton(
              tooltip: '重新生成',
              onPressed: () => _handleRefresh(context),
              icon: const Icon(Icons.shuffle_rounded),
            ),
          const _SettingsButton(),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = _containerMaxWidth(w);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(isLarge ? 24 : 16, 16, isLarge ? 24 : 16, isLarge ? 24 : 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 天氣資訊
                    const WeatherBar(),
                    const SizedBox(height: 16),

                    // 桌面版統計卡片（僅 lg 顯示）
                    if (isLarge) _DesktopStats(),

                    // 每日推薦標題 + 重新生成（桌面顯示按鈕；小螢幕移到 AppBar）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _TitleWithSub(
                          title: '今日推薦穿搭',
                          subtitle: '根據天氣、你的風格偏好和衣櫃單品，為你推薦 3 套穿搭',
                        ),
                        if (isLarge)
                          OutlinedButton.icon(
                            onPressed: () => _handleRefresh(context),
                            icon: const Icon(Icons.shuffle_rounded, size: 18),
                            label: const Text('重新生成'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 推薦穿搭卡片
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridCols(w),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 4/3,
                      ),
                      itemCount: mockOutfits.length,
                      itemBuilder: (context, i) {
                        final o = mockOutfits[i];
                        return OutfitRecommendCard(
                          outfit: o,
                          onSave: () => _handleSave(context, o.id),
                          onShare: () => _handleShare(context, o.id),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets (drop-in replacements for your React components)
// ---------------------------------------------------------------------------

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '設定',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () {},
    );
  }
}

class WeatherBar extends StatelessWidget {
  const WeatherBar({super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('台北 · 晴時多雲', style: t.titleMedium),
                  const SizedBox(height: 2),
                  Text('20° / 26° · 濕度 65% · 風 3m/s', style: t.bodySmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.umbrella_outlined),
            const SizedBox(width: 6),
            Text('降雨 20%', style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DesktopStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget stat(String title, String value, IconData icon, Color color) => Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.bodySmall?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 6),
                Text(value, style: t.headlineSmall),
              ],
            ),
            Icon(icon, size: 28, color: color),
          ],
        ),
      ),
    );

    return Row(
      children: [
        Expanded(child: stat('本週穿搭', '12 套', Icons.calendar_today_outlined, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: stat('衣櫃單品', '42 件', Icons.inventory_2_outlined, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: stat('風格匹配', '92%', Icons.trending_up, Colors.purple)),
      ],
    );
  }
}

class OutfitRecommendCard extends StatelessWidget {
  const OutfitRecommendCard({super.key, required this.outfit, required this.onSave, required this.onShare});
  final Outfit outfit;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image placeholder
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.checkroom_outlined, size: 64, color: Colors.black54),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outfit.title, style: t.titleMedium),
                const SizedBox(height: 4),
                Text(outfit.subtitle, style: t.bodySmall?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final tag in outfit.tags) Chip(label: Text(tag), visualDensity: VisualDensity.compact)],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(onPressed: onSave, icon: const Icon(Icons.bookmark_border, size: 18), label: const Text('收藏')),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(onPressed: onShare, icon: const Icon(Icons.ios_share, size: 18), label: const Text('分享')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.description, required this.actionLabel, required this.onAction});
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text(title, style: t.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(description, style: t.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _TitleWithSub extends StatelessWidget {
  const _TitleWithSub({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: t.bodySmall?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
