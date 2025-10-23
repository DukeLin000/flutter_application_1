// lib/pages/wardrobe_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';

// ⬇️ 把路徑換成你的實際位置：lib/widgets/add_item_dialog.dart
import 'package:flutter_application_1/widgets/ui/add_item_dialog.dart' as adddlg;

/// ---------------------------------------------------------------------------
/// Model + Mock Data (本頁用的輕量模型；新增時會由 add_item_dialog 的資料轉換而來)
/// ---------------------------------------------------------------------------
class ClothingItem {
  final String id;
  final String category; // 'top' | 'bottom' | 'outerwear' | 'shoes' | 'accessory'
  final String subCategory; // 針織衫、工裝褲...
  final String? brand;
  final String imageUrl; // 可是 http(s) 或 data:image/...;base64,XXXX
  final List<String> tags;

  ClothingItem({
    required this.id,
    required this.category,
    required this.subCategory,
    this.brand,
    this.imageUrl = '',
    this.tags = const [],
  });
}

final List<ClothingItem> mockClothingItems = [
  ClothingItem(id: '1', category: 'top', subCategory: '針織衫', brand: 'Uniqlo', tags: ['春秋', '休閒']),
  ClothingItem(id: '2', category: 'bottom', subCategory: '直筒褲', brand: 'GU', tags: ['上班', '百搭']),
  ClothingItem(id: '3', category: 'outerwear', subCategory: '機能外套', brand: 'H&M', tags: ['防風', '戶外']),
  ClothingItem(id: '4', category: 'shoes', subCategory: '運動鞋', brand: 'Nike', tags: ['運動', '街頭']),
  ClothingItem(id: '5', category: 'top', subCategory: '襯衫', brand: 'ZARA', tags: ['正式', '夏']),
  ClothingItem(id: '6', category: 'bottom', subCategory: '工裝褲', brand: 'Carhartt', tags: ['街頭']),
  ClothingItem(id: '7', category: 'outerwear', subCategory: '西裝外套', brand: 'ZARA', tags: ['上班']),
  ClothingItem(id: '8', category: 'shoes', subCategory: '樂福鞋', brand: 'Dr. Martens', tags: ['上班', '正式']),
];

/// ---------------------------------------------------------------------------
/// RWD WardrobePage (Web / iPhone 全系列 / Android 各尺寸)
/// ---------------------------------------------------------------------------
class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  String viewMode = 'grid'; // grid | list
  late List<ClothingItem> items;
  String selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    items = List.of(mockClothingItems);
  }

  // ------------------ RWD helpers ------------------
  double _containerMaxWidth(double w) {
    if (w >= 1600) return 1200; // very wide desktop
    if (w >= 1200) return 1100; // desktop
    if (w >= 900) return 900;   // tablet
    if (w >= 600) return 760;   // small tablet / landscape phone
    return w - 24;              // phone portrait gutters
  }

  int _gridCols(double w) {
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    return 2;
  }

  double _tileAspectRatio(double w) {
    if (w >= 1200) return 0.78;
    if (w >= 900) return 0.76;
    return 0.74;
  }

  // ------------------ Derived ------------------
  List<Map<String, dynamic>> get _categories {
    int countCat(String id) => items.where((i) => i.category == id).length;
    return [
      {'id': 'all', 'label': '全部', 'count': items.length},
      {'id': 'top', 'label': '上衣', 'count': countCat('top')},
      {'id': 'bottom', 'label': '下身', 'count': countCat('bottom')},
      {'id': 'outerwear', 'label': '外套', 'count': countCat('outerwear')},
      {'id': 'shoes', 'label': '鞋子', 'count': countCat('shoes')},
      {'id': 'accessory', 'label': '配件', 'count': countCat('accessory')},
    ];
  }

  List<ClothingItem> get _filteredItems =>
      selectedCategory == 'all' ? items : items.where((i) => i.category == selectedCategory).toList();

  // ------------------ Mapping：add_item_dialog -> 本頁模型 ------------------
  String _catToStr(adddlg.Category c) {
    switch (c) {
      case adddlg.Category.top:
        return 'top';
      case adddlg.Category.bottom:
        return 'bottom';
      case adddlg.Category.outerwear:
        return 'outerwear';
      case adddlg.Category.shoes:
        return 'shoes';
      case adddlg.Category.accessory:
        return 'accessory';
    }
    // 保底（避免分析器判斷「可能未回傳」）
    return 'top';
  }

  ClothingItem _mapFromDialog(adddlg.ClothingItem s) => ClothingItem(
        id: s.id,
        category: _catToStr(s.category),
        subCategory: s.subCategory,
        brand: s.brand,
        imageUrl: s.imageUrl,
        tags: s.tags,
      );

  // ------------------ Actions ------------------
  void _openFilter() async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => const _FilterSheet(),
    );
  }

  Future<void> _addItem() async {
    final created = await adddlg.showAddItemDialog(context);
    if (created != null) {
      setState(() => items.insert(0, _mapFromDialog(created)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已新增衣物')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('衣櫃管理'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              w >= 1200 ? 24 : 16,
              16,
              w >= 1200 ? 24 : 16,
              w >= 1200 ? 24 : 88,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 工具列
                Row(
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'grid', label: Text('網格'), icon: Icon(Icons.grid_view)),
                        ButtonSegment(value: 'list', label: Text('列表'), icon: Icon(Icons.view_list)),
                      ],
                      selected: {viewMode},
                      onSelectionChanged: (s) => setState(() => viewMode = s.first),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _openFilter,
                      icon: const Icon(Icons.filter_alt_outlined, size: 18),
                      label: const Text('篩選'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('新增'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 分類標籤（可水平捲動）
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final bool active = selectedCategory == cat['id'];
                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          backgroundColor: active ? Theme.of(context).colorScheme.primary : null,
                          foregroundColor: active ? Colors.white : null,
                          side: active ? BorderSide(color: Theme.of(context).colorScheme.primary) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        onPressed: () => setState(() => selectedCategory = cat['id'] as String),
                        child: Text('${cat['label']} (${cat['count']})'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // 內容
                if (viewMode == 'grid')
                  LayoutBuilder(builder: (context, c) {
                    final cols = _gridCols(c.maxWidth);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: _tileAspectRatio(c.maxWidth),
                      ),
                      itemCount: _filteredItems.length,
                      itemBuilder: (_, i) => _GridCard(item: _filteredItems[i]),
                    );
                  })
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ListCard(item: _filteredItems[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------ Cards ------------------
class _GridCard extends StatelessWidget {
  const _GridCard({required this.item});
  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _ImageBox(url: item.imageUrl)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.subCategory, style: t.bodyMedium),
                if (item.brand != null) ...[
                  const SizedBox(height: 2),
                  Text(item.brand!, style: t.bodySmall?.copyWith(color: Colors.grey[600])),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in item.tags.take(2))
                      Chip(label: Text(tag), visualDensity: VisualDensity.compact)
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

class _ListCard extends StatelessWidget {
  const _ListCard({required this.item});
  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _ImageBox(url: item.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.subCategory, style: t.titleMedium),
                  if (item.brand != null) ...[
                    const SizedBox(height: 2),
                    Text(item.brand!, style: t.bodySmall?.copyWith(color: Colors.grey[600])),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in item.tags)
                        Chip(label: Text(tag), visualDensity: VisualDensity.compact)
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 網路圖 / base64 dataURL 都支援；錯誤情況顯示 Placeholder
class _ImageBox extends StatelessWidget {
  const _ImageBox({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: Icon(Icons.image_outlined, color: Colors.black54)),
    );

    if (url.isEmpty) return placeholder;

    if (url.startsWith('data:image')) {
      try {
        final comma = url.indexOf(',');
        final b64 = comma >= 0 ? url.substring(comma + 1) : '';
        final bytes = base64Decode(b64);
        return Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder);
      } catch (_) {
        return placeholder;
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (c, w, p) => p == null ? w : placeholder,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

/// ------------------ Filter Sheet (示意) ------------------
class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget group(String title, List<String> chips) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final c in chips) FilterChip(label: Text(c), onSelected: (_) {})],
            ),
          ],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined),
              const SizedBox(width: 8),
              Text('篩選條件', style: t.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          group('場合', const ['休閒', '正式', '運動']),
          const SizedBox(height: 16),
          group('季節', const ['春', '夏', '秋', '冬']),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('套用')),
        ],
      ),
    );
  }
}
