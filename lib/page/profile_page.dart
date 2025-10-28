import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onNavigate});
  final void Function(String page) onNavigate;

  // ---- RWD helpers ---------------------------------------------------------
  double _containerMaxWidth(double w) {
    if (w >= 1600) return 1200; // very wide desktop
    if (w >= 1200) return 1100; // desktop
    if (w >= 900) return 900;   // tablet
    if (w >= 600) return 760;   // small tablet / landscape
    return w - 24;              // phones: keep gutters
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('個人中心')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(w >= 1200 ? 24 : 16, 16, w >= 1200 ? 24 : 16, w >= 1200 ? 24 : 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 用戶資料卡 -----------------------------------------------------
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const _Avatar(
                              url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                              size: 72,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('型男阿傑', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text('175cm / 70kg / Regular Fit',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: const [
                                      _TagChip('街頭風格'),
                                      _TagChip('機能風'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            _Stat(title: '衣櫃單品', value: '42'),
                            _Stat(title: '已儲存', value: '15'),
                            _Stat(title: '獲得讚', value: '128'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 功能選單 -------------------------------------------------------
                const SizedBox(height: 4),
                _MenuCard(
                  icon: Icons.bookmark_border,
                  title: '我的收藏',
                  description: '已儲存的穿搭組合',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.trending_up,
                  title: '我的分享',
                  description: '分享到社群的穿搭',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.inventory_2_outlined,
                  title: '膠囊衣櫥',
                  description: '管理你的膠囊衣櫥計畫',
                  onTap: () => onNavigate('capsule'),
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.storefront_outlined,
                  title: '購物建議',
                  description: '探索在地可購商品',
                  onTap: () => onNavigate('shop'),
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.notifications_outlined,
                  title: '通知設定',
                  description: '每日穿搭、降雨提醒',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.settings_outlined,
                  title: '個人設定',
                  description: '編輯個人資料、風格偏好',
                    onTap: () {
                    debugPrint('[ProfilePage] tap settings'); // 可留著看log
                    onNavigate('settings');
                    },
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.privacy_tip_outlined,
                  title: '隱私與授權',
                  description: '管理你的數據與隱私',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== 小元件們 =========================================================

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, this.size = 64});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
      child: url.isEmpty
          ? Icon(Icons.person, size: size * 0.6, color: Colors.grey.shade500)
          : null,
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      labelStyle: const TextStyle(fontSize: 12),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: t.headlineSmall),
          const SizedBox(height: 4),
          Text(title, style: t.bodySmall?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // blue-50
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB)), // blue-600
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
