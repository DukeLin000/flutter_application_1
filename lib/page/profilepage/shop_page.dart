import 'package:flutter/material.dart';
// Optional: url_launcher for external links
// import 'package:url_launcher/url_launcher.dart';

/// -------------------------------
/// Model & mock data (replace)
/// -------------------------------
class ShopItem {
  final String id;
  final String name;
  final String brand;
  final String category; // shirt | outerwear | pants | shoes | accessory
  final int price; // NT$
  final String priceRange; // budget | mid | premium
  final String imageUrl;
  final String storeLink;
  final bool availableLocally;
  final String? sizeHint;
  const ShopItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.priceRange,
    required this.imageUrl,
    required this.storeLink,
    required this.availableLocally,
    this.sizeHint,
  });
}

const List<ShopItem> mockShopItems = [
  ShopItem(
    id: '1',
    name: '寬版口袋襯衫',
    brand: 'Uniqlo',
    category: 'shirt',
    price: 990,
    priceRange: 'budget',
    imageUrl: 'https://images.unsplash.com/photo-1520975916090-3105956dac38?q=80&w=1200&auto=format&fit=crop',
    storeLink: 'https://www.uniqlo.com/tw/',
    availableLocally: true,
    sizeHint: '175cm/70kg 建議 L 號，肩寬合適。',
  ),
  ShopItem(
    id: '2',
    name: '機能防風外套',
    brand: 'H&M',
    category: 'outerwear',
    price: 1990,
    priceRange: 'mid',
    imageUrl: 'https://images.unsplash.com/photo-1602810318383-9e3d5b0b2b55?q=80&w=1200&auto=format&fit=crop',
    storeLink: 'https://www2.hm.com/zh_asia2/index.html',
    availableLocally: true,
  ),
  ShopItem(
    id: '3',
    name: '直筒長褲',
    brand: 'ZARA',
    category: 'pants',
    price: 1290,
    priceRange: 'mid',
    imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?q=80&w=1200&auto=format&fit=crop',
    storeLink: 'https://www.zara.com/tw/',
    availableLocally: true,
  ),
  ShopItem(
    id: '4',
    name: '白色休閒鞋',
    brand: 'Adidas',
    category: 'shoes',
    price: 3290,
    priceRange: 'premium',
    imageUrl: 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?q=80&w=1200&auto=format&fit=crop',
    storeLink: 'https://www.adidas.com.tw/',
    availableLocally: true,
  ),
  ShopItem(
    id: '5',
    name: '棒球帽',
    brand: 'New Era',
    category: 'accessory',
    price: 1190,
    priceRange: 'mid',
    imageUrl: 'https://images.unsplash.com/photo-1598403031688-a2f75b9b0f98?q=80&w=1200&auto=format&fit=crop',
    storeLink: 'https://www.neweracap.com.tw/',
    availableLocally: true,
  ),
];

/// -------------------------------
/// ShopPage (Web / iPhone / Android) — FINAL RWD
/// -------------------------------
class ShopPage extends StatefulWidget {
  const ShopPage({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final TextEditingController _search = TextEditingController();
  String selectedCategory = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---------- RWD helpers ----------
  double _containerMaxWidth(double w) {
    if (w >= 1600) return 1200;
    if (w >= 1200) return 1100;
    if (w >= 900) return 900;
    if (w >= 600) return 760;
    return w - 24;
  }

  int _gridCols(double w) {
    if (w >= 1200) return 3; // lg
    if (w >= 900) return 2;  // md
    return 1;                // sm
  }

  // ★ 重要：提高卡片高度，徹底避免 bottom overflow（含尺寸提示 + 按鈕）
  double _cardAspect(double w) {
    if (w >= 1200) return 0.58; // 3 欄
    if (w >= 900) return 0.62;  // 2 欄
    return 0.70;                // 1 欄
  }

  // ---------- Data / filter ----------
  final List<Map<String, String>> categories = const [
    {'id': 'all', 'label': '全部'},
    {'id': 'shirt', 'label': '襯衫'},
    {'id': 'outerwear', 'label': '外套'},
    {'id': 'pants', 'label': '褲子'},
    {'id': 'shoes', 'label': '鞋子'},
    {'id': 'accessory', 'label': '配件'},
  ];

  List<ShopItem> _filteredItems() {
    final q = _search.text.trim().toLowerCase();
    return mockShopItems.where((it) {
      final matchSearch = q.isEmpty ||
          it.name.toLowerCase().contains(q) ||
          it.brand.toLowerCase().contains(q);
      final matchCat = selectedCategory == 'all' ||
          it.category.toLowerCase().contains(selectedCategory);
      return matchSearch && matchCat;
    }).toList();
  }

  // ---------- UI helpers ----------
  Color _rangeBg(String r) {
    switch (r) {
      case 'budget':
        return Colors.green.withOpacity(.12);
      case 'mid':
        return Colors.blue.withOpacity(.12);
      case 'premium':
        return Colors.purple.withOpacity(.12);
      default:
        return Colors.grey.withOpacity(.12);
    }
  }

  Color _rangeText(String r) {
    switch (r) {
      case 'budget':
        return const Color(0xFF166534);
      case 'mid':
        return const Color(0xFF1D4ED8);
      case 'premium':
        return const Color(0xFF6B21A8);
      default:
        return Colors.grey;
    }
  }

  String _rangeLabel(String r) {
    switch (r) {
      case 'budget':
        return '親民';
      case 'mid':
        return '中價位';
      case 'premium':
        return '高端';
      default:
        return '';
    }
  }

  Future<void> _openLink(String url) async {
    // final uri = Uri.parse(url);
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri, mode: LaunchMode.externalApplication);
    //   return;
    // }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('開啟連結：$url')));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final filtered = _filteredItems();

    return Scaffold(
      appBar: AppBar(title: const Text('在地可購')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(w >= 1200 ? 24 : 16, 16, w >= 1200 ? 24 : 16, w >= 1200 ? 24 : 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.onBack != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('返回個人中心'),
                    ),
                  ),

                Card(
                  color: const Color(0xFFEFFDF5),
                  elevation: 0,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('🛍️ 在地購物建議', style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('根據你的膠囊衣櫥計畫，推薦台灣在地可購買的單品，支持本地商家，快速收到商品！'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _SearchField(controller: _search, onChanged: (_) => setState(() {})),
                const SizedBox(height: 12),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      for (final c in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c['label']!),
                            selected: selectedCategory == c['id'],
                            onSelected: (_) => setState(() => selectedCategory = c['id']!),
                          ),
                        ),
                    ],
                  ),
                ),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridCols(w),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: _cardAspect(w), // ★ 避免溢位
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _ShopItemCard(
                    item: filtered[i],
                    rangeBg: _rangeBg(filtered[i].priceRange),
                    rangeText: _rangeText(filtered[i].priceRange),
                    rangeLabel: _rangeLabel(filtered[i].priceRange),
                    onOpen: () => _openLink(filtered[i].storeLink),
                  ),
                ),

                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text('找不到相關商品', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: '搜尋商品或品牌...',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.rangeBg,
    required this.rangeText,
    required this.rangeLabel,
    required this.onOpen,
  });

  final ShopItem item;
  final Color rangeBg;
  final Color rangeText;
  final String rangeLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_outlined)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: t.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.brand,
                            style: t.bodySmall?.copyWith(color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (item.availableLocally)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('在地', style: TextStyle(fontSize: 12, color: Color(0xFF166534))),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 18, color: Colors.black54),
                    Text('NT\$ ${_ShopItemCard.formatPrice(item.price)}', style: t.titleMedium),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: rangeBg, borderRadius: BorderRadius.circular(999)),
                      child: Text(rangeLabel, style: TextStyle(fontSize: 12, color: rangeText)),
                    ),
                  ],
                ),
                if (item.sizeHint != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(item.sizeHint!, style: t.bodySmall?.copyWith(color: const Color(0xFF1E3A8A)))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onOpen,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('前往購買'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String formatPrice(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final rev = s.length - i;
      buf.write(s[i]);
      if (rev > 1 && rev % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
