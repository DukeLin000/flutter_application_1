import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------------
class CapsuleItem {
  final String category; // e.g. 上衣
  final String subCategory; // e.g. 針織衫
  final String priority; // 'must' | 'recommended' | 'optional'
  final int quantity; // 建議件數
  bool owned; // 是否已擁有

  CapsuleItem({
    required this.category,
    required this.subCategory,
    required this.priority,
    required this.quantity,
    this.owned = false,
  });
}

class CapsuleTemplate {
  final String key;
  final String name;
  final int minItems;
  final List<CapsuleItem> items;
  CapsuleTemplate({required this.key, required this.name, required this.minItems, required this.items});
}

class ShopItem {final String id; final String brand; final String price; final String imageUrl; const ShopItem({required this.id, required this.brand, required this.price, required this.imageUrl});}

/// ---------------------------------------------------------------------------
/// Demo data (你可以替換為真實資料來源)
/// ---------------------------------------------------------------------------
final Map<String, CapsuleTemplate> capsuleTemplates = {
  'street': CapsuleTemplate(
    key: 'street',
    name: '街頭風格',
    minItems: 8,
    items: [
      CapsuleItem(category: '外套', subCategory: '機能外套', priority: 'must', quantity: 1),
      CapsuleItem(category: '上衣', subCategory: '大學T', priority: 'must', quantity: 2),
      CapsuleItem(category: '褲裝', subCategory: '寬版褲', priority: 'recommended', quantity: 2),
      CapsuleItem(category: '鞋款', subCategory: '運動鞋', priority: 'recommended', quantity: 1),
      CapsuleItem(category: '配件', subCategory: '棒球帽', priority: 'optional', quantity: 1),
    ],
  ),
  'outdoor': CapsuleTemplate(
    key: 'outdoor',
    name: '戶外機能',
    minItems: 7,
    items: [
      CapsuleItem(category: '外套', subCategory: '防風外套', priority: 'must', quantity: 1),
      CapsuleItem(category: '上衣', subCategory: '排汗衣', priority: 'must', quantity: 2),
      CapsuleItem(category: '褲裝', subCategory: '機能長褲', priority: 'recommended', quantity: 2),
      CapsuleItem(category: '配件', subCategory: '機能帽', priority: 'optional', quantity: 1),
    ],
  ),
  'office': CapsuleTemplate(
    key: 'office',
    name: '上班族',
    minItems: 9,
    items: [
      CapsuleItem(category: '外套', subCategory: '西裝外套', priority: 'must', quantity: 1),
      CapsuleItem(category: '上衣', subCategory: '襯衫', priority: 'must', quantity: 3),
      CapsuleItem(category: '褲裝', subCategory: '西裝褲', priority: 'recommended', quantity: 2),
      CapsuleItem(category: '鞋款', subCategory: '樂福鞋', priority: 'optional', quantity: 1),
    ],
  ),
};

const List<ShopItem> mockShopItems = [
  ShopItem(id: 's1', brand: 'Uniqlo', price: r'NT$990', imageUrl: ''),
  ShopItem(id: 's2', brand: 'GU', price: r'NT$790', imageUrl: ''),
  ShopItem(id: 's3', brand: 'ZARA', price: r'NT$1,290', imageUrl: ''),
  ShopItem(id: 's4', brand: 'H&M', price: r'NT$599', imageUrl: ''),
];

/// ---------------------------------------------------------------------------
/// CapsulePage — Flutter 版 (RWD: Web / iOS 全系列 / Android 各尺寸)
/// ---------------------------------------------------------------------------
class CapsulePage extends StatefulWidget {
  const CapsulePage({super.key});

  @override
  State<CapsulePage> createState() => _CapsulePageState();
}

class _CapsulePageState extends State<CapsulePage> with TickerProviderStateMixin {
  String selected = 'street';
  late List<CapsuleItem> items;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    items = [...capsuleTemplates[selected]!.items];
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ------------------ RWD helpers ------------------
  double _containerMaxWidth(double w) {
    if (w >= 1600) return 1200; // 超寬桌面
    if (w >= 1200) return 1100; // 桌面
    if (w >= 900) return 900;   // 平板
    if (w >= 600) return 760;   // 小平板/橫向手機
    return w - 24;              // 直向手機：保留左右間距
  }

  bool _isLg(double w) => w >= 1200;

  // ------------------ Derived ------------------
  int get ownedCount => items.where((i) => i.owned).length;
  int get totalCount => items.length;
  double get progress => totalCount == 0 ? 0 : ownedCount / totalCount;

  List<CapsuleItem> _by(String p) => items.where((i) => i.priority == p).toList();

  // ------------------ Actions ------------------
  void _toggleOwned(int index) => setState(() => items[index].owned = !items[index].owned);

  void _switchTemplate(String key) {
    setState(() {
      selected = key;
      items = [...capsuleTemplates[key]!.items];
    });
  }

  Color _priorityBg(String p, BuildContext ctx) {
    final c = Theme.of(ctx).colorScheme;
    switch (p) {
      case 'must': return Colors.red.withOpacity(.10);
      case 'recommended': return Colors.amber.withOpacity(.16);
      case 'optional': return Colors.green.withOpacity(.12);
      default: return c.surfaceContainerHighest;
    }
  }

  Color _priorityText(String p) {
    switch (p) {
      case 'must': return const Color(0xffb91c1c); // red-700
      case 'recommended': return const Color(0xffa16207); // yellow-700
      case 'optional': return const Color(0xff166534); // green-700
      default: return Colors.grey.shade700;
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'must': return '必補';
      case 'recommended': return '建議';
      case 'optional': return '可選';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isLg = _isLg(w);

    final tpl = capsuleTemplates[selected]!;
    final must = _by('must');
    final rec = _by('recommended');
    final opt = _by('optional');

    return Scaffold(
      appBar: AppBar(title: const Text('膠囊衣櫥')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(isLg ? 24 : 16, 16, isLg ? 24 : 16, isLg ? 24 : 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 模板選擇
                _TemplatePicker(selected: selected, onSelected: _switchTemplate),
                const SizedBox(height: 12),

                // 進度卡片
                _ProgressCard(progress: progress, owned: ownedCount, total: totalCount, templateName: tpl.name, minItems: tpl.minItems),
                const SizedBox(height: 12),

                // 缺口清單 (Tabs)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TabBar(
                          controller: _tab,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                          tabs: [
                            Tab(text: '必補 (${must.length})'),
                            Tab(text: '建議 (${rec.length})'),
                            Tab(text: '可選 (${opt.length})'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 1000, // 保證 TabBarView 在 Web/桌面可正確估算高度 (內部列表為 shrinkWrap)
                          child: TabBarView(
                            controller: _tab,
                            children: [
                              _ItemList(items: must, onToggle: (i) => _toggleOwned(items.indexOf(must[i]))),
                              _ItemList(items: rec, onToggle: (i) => _toggleOwned(items.indexOf(rec[i]))),
                              _ItemList(items: opt, onToggle: (i) => _toggleOwned(items.indexOf(opt[i]))),
                            ],
                          ),
                        ),
                      ],
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

/// ---------------------------------------------------------------------------
/// UI Parts
/// ---------------------------------------------------------------------------
class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({required this.selected, required this.onSelected});
  final String selected; final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isNarrow = c.maxWidth < 560;
      final entries = capsuleTemplates.entries.toList();
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isNarrow ? 3 : 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final e = entries[i];
          final picked = e.key == selected;
          return OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: picked ? Theme.of(context).colorScheme.primary : null,
              foregroundColor: picked ? Colors.white : null,
              side: picked ? BorderSide(color: Theme.of(context).colorScheme.primary) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            ),
            onPressed: () => onSelected(e.key),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 22),
                const SizedBox(height: 6),
                Text(e.value.name, textAlign: TextAlign.center),
                const SizedBox(height: 2),
                Text('最少 ${e.value.minItems} 件', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
              ],
            ),
          );
        },
      );
    });
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.owned, required this.total, required this.templateName, required this.minItems});
  final double progress; final int owned; final int total; final String templateName; final int minItems;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('完成度', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
            Text('$owned / $total 件', style: Theme.of(context).textTheme.bodySmall),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(minHeight: 10, value: progress),
          ),
          const SizedBox(height: 6),
          Text('還需要 ${total - owned} 件單品來完成 $templateName 膠囊衣櫥 (至少 $minItems 件)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
        ]),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items, required this.onToggle});
  final List<CapsuleItem> items; final ValueChanged<int> onToggle;

  int _shopCols(double w) {
    if (w >= 900) return 3; // 桌面/平板
    if (w >= 600) return 3; // 橫向手機
    return 2;               // 直向手機
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text('沒有項目', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])));
    }
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ItemCard(index: i, item: items[i], onToggle: onToggle),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.index, required this.item, required this.onToggle});
  final int index; final CapsuleItem item; final ValueChanged<int> onToggle;

  Color _badgeBg(BuildContext ctx) {
    switch (item.priority) {
      case 'must': return Colors.red.withOpacity(.10);
      case 'recommended': return Colors.amber.withOpacity(.16);
      case 'optional': return Colors.green.withOpacity(.12);
      default: return Theme.of(ctx).colorScheme.surfaceContainerHighest;
    }
  }

  Color _badgeText() {
    switch (item.priority) {
      case 'must': return const Color(0xffb91c1c);
      case 'recommended': return const Color(0xffa16207);
      case 'optional': return const Color(0xff166534);
      default: return Colors.grey.shade700;
    }
  }

  String _label() {
    switch (item.priority) {
      case 'must': return '必補';
      case 'recommended': return '建議';
      case 'optional': return '可選';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => onToggle(index),
                  icon: Icon(item.owned ? Icons.check_circle : Icons.circle_outlined, color: item.owned ? Colors.green : Colors.grey),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${item.category} - ${item.subCategory}', style: t.titleMedium?.copyWith(decoration: item.owned ? TextDecoration.lineThrough : null, color: item.owned ? Colors.grey : null)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: _badgeBg(context), borderRadius: BorderRadius.circular(999)),
                        child: Text(_label(), style: TextStyle(color: _badgeText(), fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Text('需要 ${item.quantity} 件', style: t.bodySmall?.copyWith(color: Colors.grey[700])),
                    ]),
                  ]),
                ),
              ],
            ),
            if (!item.owned) ...[
              const SizedBox(height: 12),
              Text('在地可購建議：', style: t.bodySmall),
              const SizedBox(height: 8),
              LayoutBuilder(builder: (ctx, c) {
                int cols;
                if (c.maxWidth >= 900) {
                  cols = 3;
                } else if (c.maxWidth >= 600) cols = 3; else cols = 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.8),
                  itemCount: mockShopItems.length.clamp(0, 3),
                  itemBuilder: (_, i) => _ShopTile(mockShopItems[i]),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile(this.item);
  final ShopItem item;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 讓圖片彈性撐滿剩餘高度，避免 Grid 固定高時溢位
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(child: Icon(Icons.image_outlined)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.brand,
            style: t.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 14),
              Flexible(child: Text(item.price, style: t.bodySmall, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }
}

