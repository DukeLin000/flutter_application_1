import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_client.dart';
import 'package:flutter_application_1/theme/s_flow_design.dart'; // ✅ 引入設計系統

// ✅ 引入通知 widget (若尚未建立 S-FLOW 版通知，這裡暫時使用；建議後續也改為玻璃風格)
import 'package:flutter_application_1/widgets/ui/notification_widget.dart';

/// ---------------------------------------------------------------------------
/// Model (對接後端 OutfitDto)
/// ---------------------------------------------------------------------------
class Outfit {
  final String id;
  final String title;
  final String subtitle; // e.g. weather, temp
  final List<String> tags; // e.g. style chips
  final String? imageUrl; // ✅ 支援圖片

  Outfit({
    required this.id,
    required this.title,
    required this.subtitle,
    this.tags = const [],
    this.imageUrl,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    String notes = json['notes']?.toString() ?? '';
    if (notes.trim().isEmpty) notes = '我的穿搭 #$id';

    return Outfit(
      id: id,
      title: notes,
      subtitle: '24°C · 舒適', 
      tags: const ['休閒', '日常'],
      imageUrl: json['imageUrl'], 
    );
  }
}

/// ---------------------------------------------------------------------------
/// HomePage (S-FLOW Redesign)
/// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.hasItems,
    required this.onAddItems,
    // ✅ 接收來自 main.dart 的主題控制
    this.onThemeToggle,
    this.currentColors,
  });

  final bool hasItems;
  final VoidCallback onAddItems;
  final VoidCallback? onThemeToggle;
  final SFlowColors? currentColors;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Outfit> outfits = [];
  bool _isLoading = false;
  bool _didLoadOnce = false;

  List<AppNotification> _notifications = [];
  bool _isNotiLoading = false;
  bool _didLoadNotiOnce = false;

  // 取得當前主題顏色 (若未傳入則使用預設金色)
  SFlowColors get colors => widget.currentColors ?? SFlowThemes.gold;

  @override
  void initState() {
    super.initState();
    _fetchOutfits();
    _fetchNotifications();
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
        // 暫時不顯示 snack bar 避免干擾，或改用其他方式提示
      }
    } finally {
      _didLoadOnce = true;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isNotiLoading = true);

    try {
      // Mock notifications (模擬資料)
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
    } finally {
      _didLoadNotiOnce = true;
      if (mounted) setState(() => _isNotiLoading = false);
    }
  }

  void _handleRefresh() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('正在更新穿搭建議...', style: TextStyle(color: colors.text))));
    _fetchOutfits();
  }

  void _handleSave(String id) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('穿搭已儲存到收藏', style: TextStyle(color: colors.text))));
  }
  
  void _handleShare(String id) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('穿搭分享連結已複製', style: TextStyle(color: colors.text))));
  }

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
      SnackBar(
        content: Text(msg, style: TextStyle(color: colors.primary)),
        backgroundColor: Colors.black.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.glassBorder),
        ),
      ),
    );
  }

  // ----- RWD helpers -----
  double _containerMaxWidth(double w) => w >= 1600 ? 1400 : (w >= 1200 ? 1200 : (w >= 900 ? 980 : (w >= 600 ? 760 : w - 24)));
  int _gridCols(double w) => w >= 1200 ? 3 : (w >= 900 ? 2 : 1);
  bool _isLarge(double w) => w >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isLarge = _isLarge(w);

        return Scaffold(
          backgroundColor: Colors.transparent, // ★ 透明背景
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                // S-FLOW Logo (點擊切換主題)
                GestureDetector(
                  onTap: widget.onThemeToggle,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: colors.accentGradient),
                      boxShadow: [BoxShadow(color: colors.glow, blurRadius: 8)],
                    ),
                    child: const Center(
                      child: Text('S', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'TODAY\'S PICK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 20, 
                    color: colors.text,
                    letterSpacing: 1.2,
                    shadows: [Shadow(color: colors.glow, blurRadius: 10)],
                  ),
                ),
              ],
            ),
            actions: [
              if (!isLarge)
                IconButton(
                  tooltip: '重新生成',
                  onPressed: _handleRefresh,
                  icon: Icon(Icons.shuffle_rounded, color: colors.secondary),
                ),
              IconButton(
                tooltip: '設定',
                icon: Icon(Icons.settings_outlined, color: colors.text),
                onPressed: () {}, // TODO: Go to settings
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: colors.primary))
              : RefreshIndicator(
                  color: colors.primary,
                  backgroundColor: Colors.black,
                  onRefresh: () async {
                    await _fetchOutfits();
                    await _fetchNotifications();
                  },
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          isLarge ? 24 : 16, 16, isLarge ? 24 : 16, isLarge ? 24 : 88,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 通知區塊 (使用 GlassContainer 包覆)
                            if (!_isNotiLoading && _notifications.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GlassContainer(
                                  colors: colors,
                                  padding: EdgeInsets.zero, 
                                  child: NotificationWidget(
                                    notifications: _notifications,
                                    onViewAll: () => _snack('開啟通知列表'),
                                    onDismiss: _dismissNoti,
                                  ),
                                ),
                              ),

                            // 天氣欄
                            GlassWeatherBar(colors: colors),
                            const SizedBox(height: 16),

                            if (isLarge) DesktopStatsSection(colors: colors),
                            if (isLarge) const SizedBox(height: 16),

                            // 標題區
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI 推薦穿搭',
                                      style: TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.w600,
                                        color: colors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '來自你的衣櫃與風格分析',
                                      style: TextStyle(color: colors.textDim, fontSize: 12),
                                    ),
                                  ],
                                ),
                                if (isLarge)
                                  GlassButton(
                                    onPressed: _handleRefresh,
                                    icon: Icons.shuffle_rounded,
                                    label: '重新生成',
                                    colors: colors,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (outfits.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.checkroom_outlined, size: 48, color: colors.textDim),
                                      const SizedBox(height: 16),
                                      Text(
                                        '暫無穿搭建議，請先到衣櫃新增單品',
                                        style: TextStyle(color: colors.textDim),
                                      ),
                                      const SizedBox(height: 16),
                                      FilledButton.icon(
                                        onPressed: widget.onAddItems,
                                        icon: const Icon(Icons.add),
                                        label: const Text('新增單品'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: colors.primary,
                                          foregroundColor: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _gridCols(w),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 4 / 3,
                                ),
                                itemCount: outfits.length,
                                itemBuilder: (context, i) {
                                  final o = outfits[i];
                                  return GlassOutfitCard(
                                    outfit: o,
                                    colors: colors,
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
}

// ==========================================
// S-FLOW Components (Local)
// ==========================================

class GlassWeatherBar extends StatelessWidget {
  final SFlowColors colors;
  const GlassWeatherBar({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      colors: colors,
      child: Row(
        children: [
          Icon(Icons.wb_sunny_outlined, color: colors.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: colors.secondary),
                    const SizedBox(width: 4),
                    Text('台北市', style: TextStyle(color: colors.textDim, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('24°C 晴時多雲', style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('濕度 65% · 降雨機率 20%', style: TextStyle(color: colors.textDim, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlassOutfitCard extends StatelessWidget {
  final Outfit outfit;
  final SFlowColors colors;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const GlassOutfitCard({
    super.key,
    required this.outfit,
    required this.colors,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      colors: colors,
      onTap: () {}, // 開啟詳情
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: outfit.imageUrl != null 
                ? Image.network(
                    outfit.imageUrl!, 
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: colors.textDim),
                  )
                : Icon(Icons.checkroom_outlined, size: 48, color: colors.textDim),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outfit.title, 
                  style: TextStyle(fontWeight: FontWeight.bold, color: colors.text),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  outfit.subtitle,
                  style: TextStyle(fontSize: 12, color: colors.textDim),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _GlassActionButton(icon: Icons.bookmark_border, onTap: onSave, colors: colors),
                    const Spacer(),
                    _GlassActionButton(icon: Icons.ios_share, onTap: onShare, colors: colors),
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

class DesktopStatsSection extends StatelessWidget {
  final SFlowColors colors;
  const DesktopStatsSection({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard('本週穿搭', '12 套', Icons.calendar_today, colors),
        const SizedBox(width: 12),
        _StatCard('衣櫃單品', '42 件', Icons.checkroom, colors),
        const SizedBox(width: 12),
        _StatCard('風格匹配', '92%', Icons.trending_up, colors),
      ],
    );
  }

  Widget _StatCard(String title, String val, IconData icon, SFlowColors colors) {
    return Expanded(
      child: GlassContainer(
        colors: colors,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textDim, fontSize: 12)),
                const SizedBox(height: 4),
                Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.text)),
              ],
            ),
            Icon(icon, color: colors.primary.withOpacity(0.8), size: 24),
          ],
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final SFlowColors colors;

  const GlassButton({
    super.key, required this.onPressed, required this.icon, required this.label, required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final SFlowColors colors;
  const _GlassActionButton({required this.icon, required this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 20, color: colors.secondary),
      ),
    );
  }
}