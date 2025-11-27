// lib/page/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_client.dart';

// ✅ 新增：通知 widget
import 'package:flutter_application_1/widgets/ui/notification_widget.dart';

/// ---------------------------------------------------------------------------
/// Model (對接後端 OutfitDto)
/// ---------------------------------------------------------------------------
class Outfit {
  final String id;
  final String title;
  final String subtitle; // e.g. weather, temp
  final List<String> tags; // e.g. style chips

  Outfit({
    required this.id,
    required this.title,
    required this.subtitle,
    this.tags = const [],
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id =
        rawId?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    String notes = json['notes']?.toString() ?? '';
    if (notes.trim().isEmpty) notes = '我的穿搭 #$id';

    return Outfit(
      id: id,
      title: notes,
      subtitle: '24°C · 舒適', // TODO: 後端補 weather 後改成動態
      tags: const ['休閒', '日常'], // TODO: 後端補 tags 後改成動態
    );
  }
}

/// ---------------------------------------------------------------------------
/// HomePage
/// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.hasItems, // TODO: 未來可移除，以 API 為主
    required this.onAddItems,
  });

  final bool hasItems;
  final VoidCallback onAddItems;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Outfit> outfits = [];
  bool _isLoading = false;
  bool _didLoadOnce = false; // ✅ 用來判斷是否需要顯示錯誤提示

  // ✅ 新增：通知狀態
  List<AppNotification> _notifications = [];
  bool _isNotiLoading = false;
  bool _didLoadNotiOnce = false;

  @override
  void initState() {
    super.initState();
    _fetchOutfits();
    _fetchNotifications(); // ✅ 一起抓通知
  }

  Future<void> _fetchOutfits() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final list = await ApiClient.I.listOutfits();

      if (!mounted) return;
      setState(() {
        outfits = list.map((json) => Outfit.fromJson(json)).toList();
      });
    } catch (e) {
      debugPrint('Home fetch error: $e');

      if (_didLoadOnce && mounted && outfits.isEmpty) {
        _snack('目前無法取得穿搭，請稍後再試');
      }
    } finally {
      _didLoadOnce = true;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ✅ 新增：抓通知（目前先 mock，等你後端通知 API 好再換）
  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isNotiLoading = true);

    try {
      // TODO: 後端完成後換成真的 API，例如：
      // final list = await ApiClient.I.listNotifications();
      // setState(() {
      //   _notifications = list.map((json) => AppNotification.fromJson(json)).toList();
      // });

      // ---- 暫時 mock ----
      await Future.delayed(const Duration(milliseconds: 200));
      final now = DateTime.now();
      final mock = <AppNotification>[
        AppNotification(
          id: 'n1',
          title: '穿搭建議已更新',
          message: '今日推薦穿搭已產生，快來看看～',
          isRead: false,
          timestamp: now.subtract(const Duration(minutes: 5)),
        ),
        AppNotification(
          id: 'n2',
          title: '新社群穿搭上架',
          message: '社群有新的熱門穿搭，去看看靈感吧！',
          isRead: false,
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
      ];

      if (!mounted) return;
      setState(() => _notifications = mock);
    } catch (e) {
      debugPrint('Notification fetch error: $e');

      if (_didLoadNotiOnce && mounted) {
        _snack('目前無法取得通知，請稍後再試');
      }
    } finally {
      _didLoadNotiOnce = true;
      if (mounted) setState(() => _isNotiLoading = false);
    }
  }

  void _handleRefresh() {
    _snack('正在更新穿搭建議...');
    _fetchOutfits();
  }

  void _handleSave(String id) => _snack('穿搭已儲存到收藏');
  void _handleShare(String id) => _snack('穿搭分享連結已複製');

  // ✅ 新增：通知已讀 / 關閉
  void _dismissNoti(String id) {
    setState(() {
      _notifications = _notifications.map((n) {
        if (n.id == id) {
          return AppNotification(
            id: n.id,
            title: n.title,
            message: n.message,
            isRead: true,
            timestamp: n.timestamp,
          );
        }
        return n;
      }).toList();
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ----- RWD helpers -----
  double _containerMaxWidth(double w) {
    if (w >= 1600) return 1400;
    if (w >= 1200) return 1200;
    if (w >= 900) return 980;
    if (w >= 600) return 760;
    return w - 24;
  }

  int _gridCols(double w) {
    if (w >= 1200) return 3;
    if (w >= 900) return 2;
    return 1;
  }

  bool _isLarge(double w) => w >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isLarge = _isLarge(w);

        final showEmptyState =
            !_isLoading && outfits.isEmpty && !widget.hasItems;

        if (showEmptyState) {
          return _buildEmptyState(w, isLarge);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('每日穿搭建議'),
            actions: [
              if (!isLarge)
                IconButton(
                  tooltip: '重新生成',
                  onPressed: _handleRefresh,
                  icon: const Icon(Icons.shuffle_rounded),
                ),
              const _SettingsButton(),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchOutfits();
                    await _fetchNotifications();
                  },
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: _containerMaxWidth(w)),
                      child: SingleChildScrollView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          isLarge ? 24 : 16,
                          16,
                          isLarge ? 24 : 16,
                          isLarge ? 24 : 88,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ✅ 新增：通知區塊（有未讀才顯示）
                            if (!_isNotiLoading)
                              NotificationWidget(
                                notifications: _notifications,
                                onViewAll: () {
                                  // TODO: 之後導到通知頁
                                  _snack('開啟通知列表（待實作）');
                                },
                                onDismiss: _dismissNoti,
                              ),

                            const WeatherBar(),
                            const SizedBox(height: 16),

                            if (isLarge) _DesktopStats(),
                            if (isLarge) const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const _TitleWithSub(
                                  title: '今日推薦穿搭',
                                  subtitle: '來自你的衣櫃與 AI 建議',
                                ),
                                if (isLarge)
                                  OutlinedButton.icon(
                                    onPressed: _handleRefresh,
                                    icon: const Icon(
                                      Icons.shuffle_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('重新生成'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (outfits.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text('暫無穿搭建議，請先到衣櫃新增單品'),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _gridCols(w),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 4 / 3,
                                ),
                                itemCount: outfits.length,
                                itemBuilder: (context, i) {
                                  final o = outfits[i];
                                  return OutfitRecommendCard(
                                    outfit: o,
                                    onSave: () => _handleSave(o.id),
                                    onShare: () => _handleShare(o.id),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(double w, bool isLarge) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日出裝'),
        actions: const [_SettingsButton()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isLarge ? 24 : 16,
              16,
              isLarge ? 24 : 16,
              isLarge ? 24 : 88,
            ),
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: '尚未建立衣櫃',
              description: '新增衣服單品，開始使用 AI 智能穿搭功能',
              actionLabel: '前往衣櫃',
              onAction: widget.onAddItems,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets（保持你原本的 UI）
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined,
                color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('台北 · 晴時多雲', style: t.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '20° / 26° · 濕度 65% · 風 3m/s',
                    style: t.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
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

    Widget stat(
            String title, String value, IconData icon, Color color) =>
        Card(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: t.bodySmall
                            ?.copyWith(color: Colors.grey[600])),
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
        Expanded(
            child: stat('本週穿搭', '12 套', Icons.calendar_today_outlined,
                Colors.blue)),
        const SizedBox(width: 12),
        Expanded(
            child: stat('衣櫃單品', '42 件', Icons.inventory_2_outlined,
                Colors.green)),
        const SizedBox(width: 12),
        Expanded(
            child: stat('風格匹配', '92%', Icons.trending_up,
                Colors.purple)),
      ],
    );
  }
}

class OutfitRecommendCard extends StatelessWidget {
  const OutfitRecommendCard({
    super.key,
    required this.outfit,
    required this.onSave,
    required this.onShare,
  });

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
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.checkroom_outlined,
                  size: 64, color: Colors.black54),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(outfit.title, style: t.titleMedium),
                const SizedBox(height: 4),
                Text(
                  outfit.subtitle,
                  style: t.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in outfit.tags)
                      Chip(
                        label: Text(tag),
                        visualDensity:
                            VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.bookmark_border,
                          size: 18),
                      label: const Text('收藏'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.ios_share,
                          size: 18),
                      label: const Text('分享'),
                    ),
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
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

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
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text(title,
                style: t.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              description,
              style: t.bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _TitleWithSub extends StatelessWidget {
  const _TitleWithSub({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(title, style: t.titleLarge),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style:
                t.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
