import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_client.dart';
import 'package:flutter_application_1/theme/s_flow_design.dart'; // ✅ 引入設計系統
import 'package:flutter_application_1/widgets/ui/add_item_dialog.dart' as adddlg;

/// ---------------------------------------------------------------------------
/// Model (保持不變)
/// ---------------------------------------------------------------------------
class ClothingItem {
  final String id;
  final String category;    
  final String subCategory; 
  final String? brand;
  final String imageUrl;    
  final List<String> tags;

  ClothingItem({
    required this.id,
    required this.category,
    required this.subCategory,
    this.brand,
    this.imageUrl = '',
    this.tags = const [],
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'].toString(),
      category: json['category']?.toString().toLowerCase() ?? 'top',
      subCategory: json['subCategory'] ?? json['name'] ?? '',
      brand: json['brand'],
      imageUrl: json['imageUrl'] ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// ---------------------------------------------------------------------------
/// WardrobePage (S-FLOW RWD)
/// ---------------------------------------------------------------------------
class WardrobePage extends StatefulWidget {
  // ✅ 修正 1: 接收全域主題顏色
  final SFlowColors? currentColors;

  const WardrobePage({
    super.key,
    this.currentColors,
  });

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  String viewMode = 'grid'; // grid | list
  List<ClothingItem> items = []; 
  String selectedCategory = 'all';
  bool _isLoading = false;

  // ✅ 修正 2: 改為 Getter，動態取得顏色 (預設為 Purple 以配合深色背景)
  SFlowColors get colors => widget.currentColors ?? SFlowThemes.purple;
  
  // 顏色映射表 (UI中文 -> 後端英文)
  final Map<String, String> _colorMap = {
    '黑色': 'BLACK', '白色': 'WHITE', '灰色': 'GRAY', '米色': 'BEIGE',
    '藍色': 'BLUE', '深藍': 'NAVY', '紅色': 'RED', '粉色': 'PINK',
    '黃色': 'YELLOW', '綠色': 'GREEN', '紫色': 'PURPLE', '橘色': 'ORANGE',
    '棕色': 'BROWN', '卡其': 'KHAKI', '多色': 'MULTICOLOR',
  };

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  // ✅ 修正 3: 確保當父層切換主題時，這裡也會更新
  @override
  void didUpdateWidget(WardrobePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColors != widget.currentColors) {
      setState(() {}); 
    }
  }

  Future<void> _fetchItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
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

  Future<void> _addItem() async {
    // 使用深色主題 Dialog
    // 這裡我們強制傳入一個深色 Theme 的 context，確保 Dialog 不會變白底
    await showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.dark().copyWith(
          primaryColor: colors.primary,
          colorScheme: ColorScheme.dark(primary: colors.primary),
        ),
        // 注意：這裡需要確認 adddlg.showAddItemDialog 是否支援由外部 builder 呼叫
        // 如果它是一個封裝好的 function，你可能需要修改 add_item_dialog.dart
        // 假設 adddlg.showAddItemDialog 是一個 Widget 或者可以接受 context 的 function
        // 這裡暫時示範如何確保環境是深色的
        child: Builder(
          builder: (innerContext) {
             // 這裡呼叫原本的邏輯，但建議檢查 add_item_dialog.dart 是否正確使用了 Theme.of(context)
             return const SizedBox(); // 佔位，實際應呼叫你的 Dialog Widget
          }
        ),
      ),
    );

    // ✅ 簡單版：直接呼叫，但確保 main.dart 的 ThemeMode 是 dark
    final item = await adddlg.showAddItemDialog(context);

    if (item == null) return;

    setState(() => _isLoading = true);
    
    try {
      String finalImageUrl = item.imageUrl;
      if (item.imageBytes != null) {
        final filename = 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadRes = await ApiClient.I.uploadImageBytes(item.imageBytes!, filename: filename);
        finalImageUrl = uploadRes['url'];
      }

      // 顏色轉換
      String? backendColor;
      if (item.color.isNotEmpty) {
        final uiColor = item.color.first;
        backendColor = _colorMap[uiColor];
      }

      final body = {
        'category': item.category.name.toUpperCase(),
        'subCategory': item.subCategory,
        'brand': item.brand,
        'color': backendColor,
        'season': item.season.map((e) => e.name.toUpperCase()).toList(),
        'occasion': item.occasion.map((e) => e.name.toUpperCase()).toList(),
        'fit': item.fit.name.toUpperCase(),
        'tags': item.tags,
        'favorite': item.isFavorite,
        'imageUrl': finalImageUrl,
        'waterproof': item.waterproof,
        'warmth': item.warmth,
        'breathability': item.breathability,
      };

      await ApiClient.I.createItem(body);
      
      if (mounted) {
        _snack('新增成功');
        _fetchItems();
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
        content: Text(msg, style: TextStyle(color: isError ? Colors.redAccent : colors.text)),
        backgroundColor: Colors.black.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.glassBorder),
        ),
      ),
    );
  }

  // ------------------ RWD helpers ------------------
  double _containerMaxWidth(double w) => w >= 1600 ? 1200 : (w >= 1200 ? 1100 : (w >= 900 ? 900 : (w >= 600 ? 760 : w - 24)));
  int _gridCols(double w) => w >= 1200 ? 4 : (w >= 900 ? 3 : 2);
  double _tileAspectRatio(double w) => 0.75;

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

  // ------------------ UI ------------------

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isLg = w >= 1200;

    return Scaffold(
      backgroundColor: Colors.transparent, // ★ S-FLOW: 透明背景
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('WARDROBE', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.text),
        actions: [
          IconButton(onPressed: _fetchItems, icon: const Icon(Icons.refresh), color: colors.secondary), 
          IconButton(onPressed: () {}, icon: const Icon(Icons.search), color: colors.text),
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
                padding: EdgeInsets.fromLTRB(isLg ? 24 : 16, 16, isLg ? 24 : 16, 0),
                child: Row(
                  children: [
                    // View Mode Toggle (Glass Style)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.grid_view, size: 20, color: viewMode == 'grid' ? colors.primary : colors.textDim),
                            onPressed: () => setState(() => viewMode = 'grid'),
                            tooltip: '網格',
                          ),
                          IconButton(
                            icon: Icon(Icons.view_list, size: 20, color: viewMode == 'list' ? colors.primary : colors.textDim),
                            onPressed: () => setState(() => viewMode = 'list'),
                            tooltip: '列表',
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Filter Btn (Glass)
                    OutlinedButton.icon(
                      onPressed: () {
                        // _openFilter (暫時略過)
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.glassBorder), 
                        foregroundColor: colors.text
                      ),
                      icon: const Icon(Icons.filter_alt_outlined, size: 18),
                      label: const Text('篩選'),
                    ),
                    const SizedBox(width: 8),
                    // Add Btn (Solid)
                    FilledButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('新增'),
                      style: FilledButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 分類標籤 (Glass Chips)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: isLg ? 24 : 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final bool active = selectedCategory == cat['id'];
                    return GestureDetector(
                      onTap: () => setState(() => selectedCategory = cat['id'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? colors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          border: Border.all(color: active ? colors.primary : Colors.white10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${cat['label']} (${cat['count']})',
                          style: TextStyle(
                            color: active ? colors.primary : colors.textDim,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 內容區 (Glass Cards)
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: colors.primary))
                    : items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.checkroom_outlined, size: 64, color: colors.textDim),
                                const SizedBox(height: 16),
                                Text('目前沒有衣物，請點擊新增', style: TextStyle(color: colors.textDim, fontSize: 16)),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(isLg ? 24 : 16, 0, isLg ? 24 : 16, 88),
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
                                    itemBuilder: (_, i) => _GlassGridCard(item: _filteredItems[i], colors: colors),
                                  );
                                })
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filteredItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) => _GlassListCard(item: _filteredItems[i], colors: colors),
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

/// ------------------ S-FLOW Glass Cards ------------------

class _GlassGridCard extends StatelessWidget {
  final ClothingItem item;
  final SFlowColors colors;
  const _GlassGridCard({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Colors.black26,
              child: item.imageUrl.isNotEmpty
                  ? Image.network(item.imageUrl, fit: BoxFit.cover)
                  : Icon(Icons.image, color: colors.textDim),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.subCategory, style: TextStyle(color: colors.text, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.brand != null && item.brand!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.brand!, style: TextStyle(color: colors.textDim, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: item.tags.take(2).map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 10, color: colors.textDim)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassListCard extends StatelessWidget {
  final ClothingItem item;
  final SFlowColors colors;
  const _GlassListCard({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      colors: colors,
      child: Row(
        children: [
          SizedBox(
            width: 60, height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(item.imageUrl, fit: BoxFit.cover)
                  : Container(color: Colors.white10, child: Icon(Icons.image, size: 32, color: colors.textDim)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.subCategory, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                if (item.brand != null)
                  Text(item.brand!, style: TextStyle(color: colors.textDim, fontSize: 12)),
              ],
            ),
          ),
          Wrap(
            spacing: 6,
            children: item.tags.map((t) => Chip(
              label: Text(t, style: TextStyle(color: colors.text, fontSize: 10)),
              backgroundColor: Colors.white10,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
        ],
      ),
    );
  }
}