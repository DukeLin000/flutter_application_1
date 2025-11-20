// lib/page/wardrobe_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_client.dart'; // ✅ 引入 API Client
import 'package:flutter_application_1/widgets/ui/add_item_dialog.dart' as adddlg;

/// ---------------------------------------------------------------------------
/// Model (對接後端 DTO)
/// ---------------------------------------------------------------------------
class ClothingItem {
  final String id;
  final String category;    // 'top' | 'bottom' | ... (前端習慣小寫)
  final String subCategory; // 針織衫、工裝褲...
  final String? brand;
  final String imageUrl;    // http url
  final List<String> tags;

  ClothingItem({
    required this.id,
    required this.category,
    required this.subCategory,
    this.brand,
    this.imageUrl = '',
    this.tags = const [],
  });

  // ✅ Factory: 解析後端 JSON
  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'].toString(),
      // 後端 Enum 通常是大寫 (TOP)，前端 UI 邏輯目前用小寫 (top)
      category: json['category']?.toString().toLowerCase() ?? 'top',
      // 後端 DTO 有 subCategory 也有 name，優先用 subCategory
      subCategory: json['subCategory'] ?? json['name'] ?? '',
      brand: json['brand'],
      imageUrl: json['imageUrl'] ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// ---------------------------------------------------------------------------
/// RWD WardrobePage
/// ---------------------------------------------------------------------------
class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  String viewMode = 'grid'; // grid | list
  List<ClothingItem> items = []; // ✅ 預設為空，等待 API 載入
  String selectedCategory = 'all';
  bool _isLoading = false; // ✅ 載入狀態

  @override
  void initState() {
    super.initState();
    _fetchItems(); // ✅ 啟動時載入資料
  }

  // ------------------ API Actions ------------------

  // 1. 從後端讀取列表
  Future<void> _fetchItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // 呼叫 API (ApiClient 會自動處理 Token)
      // 你也可以傳入 category 參數讓後端篩選，這裡先示範前端篩選
      final list = await ApiClient.I.listItems();
      
      if (!mounted) return;
      setState(() {
        items = list.map((json) => ClothingItem.fromJson(json)).toList();
      });
    } catch (e) {
      if (mounted) _snack('載入失敗: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. 新增衣物 (上傳圖片 + 建立資料)
  Future<void> _addItem() async {
    // 1) 開啟對話框取得使用者輸入
    final raw = await adddlg.showAddItemDialog(context);
    if (raw == null) return;

    setState(() => _isLoading = true);
    
    try {
      String finalImageUrl = raw.imageUrl;

      // 2) 如果有選圖片檔案，先上傳
      if (raw.imageBytes != null) {
        final filename = 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadRes = await ApiClient.I.uploadImageBytes(
          raw.imageBytes!,
          filename: filename,
        );
        // 後端回傳 { "url": "http://...", ... }
        finalImageUrl = uploadRes['url'];
      }

      // 3) 組裝資料呼叫後端建立 API
      final body = {
        'category': raw.category.name.toUpperCase(), // 後端 Enum 需要大寫
        'subCategory': raw.subCategory,
        'brand': raw.brand,
        'color': raw.color.isNotEmpty ? raw.color.first : null,
        'season': raw.season.map((e) => e.name.toUpperCase()).toList(),
        'occasion': raw.occasion.map((e) => e.name.toUpperCase()).toList(),
        'fit': raw.fit.name.toUpperCase(),
        'tags': raw.tags,
        'favorite': raw.isFavorite,
        'imageUrl': finalImageUrl,
        'waterproof': raw.waterproof,
        'warmth': raw.warmth,
        'breathability': raw.breathability,
      };

      await ApiClient.I.createItem(body);
      
      if (mounted) {
        _snack('新增成功');
        _fetchItems(); // ✅ 成功後重新整理列表
      }
    } catch (e) {
      if (mounted) _snack('新增失敗: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------ RWD helpers ------------------
  double _containerMaxWidth(double w) {
    if (w >= 1600) return 1200;
    if (w >= 1200) return 1100;
    if (w >= 900) return 900;
    if (w >= 600) return 760;
    return w - 24;
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

  // ------------------ Actions ------------------
  void _openFilter() async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('衣櫃管理'),
        actions: [
          // 手動重新整理按鈕
          IconButton(onPressed: _fetchItems, icon: const Icon(Icons.refresh)), 
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 工具列 (Header)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  w >= 1200 ? 24 : 16, 16, w >= 1200 ? 24 : 16, 0),
                child: Row(
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
              ),
              const SizedBox(height: 12),

              // 分類標籤 (Category Filter)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: w >= 1200 ? 24 : 16),
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

              // 內容區 (Content)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.checkroom_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text('目前沒有衣物，請點擊新增', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              w >= 1200 ? 24 : 16, 0, w >= 1200 ? 24 : 16, 88),
                            child: viewMode == 'grid'
                              ? LayoutBuilder(builder: (context, c) {
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
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filteredItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) => _ListCard(item: _filteredItems[i]),
                                ),
                          ),
              ),
            ],
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
                Text(item.subCategory, style: t.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.brand != null && item.brand!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.brand!, style: t.bodySmall?.copyWith(color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final tag in item.tags.take(2))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text(tag, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      )
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