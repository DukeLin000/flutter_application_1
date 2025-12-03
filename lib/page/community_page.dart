import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_application_1/api/api_client.dart';
import 'package:flutter_application_1/theme/s_flow_design.dart'; // ✅ 引入設計系統

// 引用衣櫃模型
import 'package:flutter_application_1/page/wardrobe_page.dart' as wardrobe;
import 'package:flutter_application_1/widgets/wardrobe_picker.dart';
import 'package:flutter_application_1/widgets/ui/add_outfit_dialog.dart';

// -----------------------------
// Models (保持不變)
// -----------------------------
class OutfitItem {
  final String brand;
  final String name;
  const OutfitItem(this.brand, this.name);
}

class Outfit {
  final String id;
  final String userName;
  final String description;
  final List<String> tags;
  final List<OutfitItem> items;
  final double aspect; 
  int likes;
  bool isLiked;
  final String? imageUrl;

  Outfit({
    required this.id,
    required this.userName,
    required this.description,
    required this.tags,
    required this.items,
    this.aspect = 4 / 3,
    this.likes = 0,
    this.isLiked = false,
    this.imageUrl,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    List<OutfitItem> parsedItems = [];
    if (json['items'] != null) {
      parsedItems = (json['items'] as List).map((i) {
        return OutfitItem(
          i['brand'] ?? '',
          i['subCategory'] ?? i['name'] ?? '單品',
        );
      }).toList();
    }
    String notes = json['description'] ?? json['notes'] ?? '';
    if (notes.isEmpty) notes = '分享穿搭';
    return Outfit(
      id: json['id'].toString(),
      userName: json['userDisplayName'] ?? 'User${json['id']}',
      description: notes,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      items: parsedItems,
      aspect: 1.0, 
      likes: json['likeCount'] ?? 0,
      isLiked: json['likedByMe'] ?? false,
      imageUrl: json['imageUrl'],
    );
  }
}

class Comment {
  final String id;
  final String userName;
  final String text;
  const Comment({required this.id, required this.userName, required this.text});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'].toString(),
      userName: json['userDisplayName'] ?? '匿名用戶',
      text: json['content'] ?? '',
    );
  }
}

// -----------------------------
// Community Page (S-FLOW RWD)
// -----------------------------
class CommunityPage extends StatefulWidget {
  // ✅ 接收全域主題顏色
  final SFlowColors? currentColors;

  const CommunityPage({
    super.key,
    this.currentColors,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<Outfit> outfits = [];
  String activeTab = 'latest';
  String viewMode = 'masonry';
  String searchQuery = '';
  bool _isLoading = false;

  // ✅ 動態取得顏色：優先使用傳入的 currentColors
  SFlowColors get colors => widget.currentColors ?? SFlowThemes.purple;

  @override
  void initState() {
    super.initState();
    _fetchOutfits();
  }

  // ✅ 當父層傳入新的顏色時 (例如從紫變金)，觸發重繪
  @override
  void didUpdateWidget(CommunityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColors != widget.currentColors) {
      setState(() {}); 
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('載入失敗: $e', style: TextStyle(color: colors.primary)),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startAddOutfitFlow() async {
    try {
      // 步驟 1: 開啟衣物選擇器
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WardrobePicker()),
      );

      if (result == null) return; 
      final selectedItems = (result as List).cast<wardrobe.ClothingItem>();
      if (selectedItems.isEmpty) return;
      if (!mounted) return;

      // 步驟 2: 開啟填寫資訊對話框
      // ✅ 修正重點：自定義 Theme，讓 Dialog 使用 S-FLOW 的主色調
      await showDialog(
        context: context,
        builder: (_) => Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: colors.primary, // 設定主色
            colorScheme: ColorScheme.dark(
              primary: colors.primary,
              secondary: colors.secondary,
              surface: Colors.grey[900]!, // 確保 Dialog 背景不會太突兀
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: colors.primary,
              selectionHandleColor: colors.primary,
            ),
          ),
          child: AddOutfitDialog(
            onSubmit: (formData) async {
              try {
                final outfitData = {
                  'description': formData.description,
                  'imageUrl': formData.imageUrl,
                  'tags': formData.tags,
                  'itemIds': selectedItems.map((i) => i.id).toList(),
                };
                await ApiClient.I.createOutfit(outfitData);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('發布成功！', style: TextStyle(color: colors.text))),
                  );
                  _fetchOutfits(); 
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('發布失敗: $e')));
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Add outfit flow error: $e');
    }
  }

  Future<void> _handleLike(String id) async {
    final idx = outfits.indexWhere((o) => o.id == id);
    if (idx < 0) return;
    final item = outfits[idx];
    setState(() {
      item.isLiked = !item.isLiked;
      item.likes += item.isLiked ? 1 : -1;
    });
    try {
      if (item.isLiked) {
        await ApiClient.I.likeOutfit(id);
      } else {
        await ApiClient.I.unlikeOutfit(id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        item.isLiked = !item.isLiked;
        item.likes += item.isLiked ? 1 : -1;
      });
    }
  }

  void _openDetail(Outfit outfit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (_) => _GlassCommentSheet(
        outfit: outfit,
        colors: colors, // ✅ 傳遞當前顏色
        onLikeToggle: () => _handleLike(outfit.id),
      ),
    );
  }

  // ------------------ RWD helpers ------------------
  double _containerMaxWidth(double w) {
    if (w >= 1600) return 1400;
    if (w >= 1200) return 1200;
    if (w >= 900) return 980;
    if (w >= 600) return 760;
    return w - 24;
  }
  bool _isLg(double w) => w >= 1200;

  // ------------------ Derived data ------------------
  List<Outfit> get _filtered {
    if (searchQuery.trim().isEmpty) return [...outfits];
    final q = searchQuery.toLowerCase();
    return outfits.where((o) {
      return o.description.toLowerCase().contains(q) ||
          o.tags.any((t) => t.toLowerCase().contains(q)) ||
          o.userName.toLowerCase().contains(q) ||
          o.items.any((it) => it.brand.toLowerCase().contains(q));
    }).toList();
  }

  List<Outfit> get _display {
    final list = [..._filtered];
    if (activeTab == 'trending') {
      list.sort((a, b) => b.likes.compareTo(a.likes));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isLg = _isLg(w);

    return Scaffold(
      backgroundColor: Colors.transparent, // ✅ 透明，顯示底層 S-FLOW 背景
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('COMMUNITY', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.text),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOutfits,
            color: colors.secondary,
            tooltip: '重新整理',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _startAddOutfitFlow,
            color: colors.primary, // ✅ 使用 S-FLOW Primary Color
            tooltip: '新增穿搭',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(isLg ? 24 : 16, 0, isLg ? 24 : 16, isLg ? 24 : 88),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tabs & View Mode
                      Row(
                        children: [
                          _GlassTab(
                            label: '最新', 
                            active: activeTab == 'latest', 
                            colors: colors, 
                            onTap: () => setState(() => activeTab = 'latest')
                          ),
                          const SizedBox(width: 8),
                          _GlassTab(
                            label: '熱門', 
                            active: activeTab == 'trending', 
                            colors: colors, 
                            onTap: () => setState(() => activeTab = 'trending')
                          ),
                          const Spacer(),
                          // View Mode Buttons
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.grid_view, size: 20, color: viewMode == 'masonry' ? colors.primary : colors.textDim),
                                  onPressed: () => setState(() => viewMode = 'masonry'),
                                ),
                                IconButton(
                                  icon: Icon(Icons.grid_on, size: 20, color: viewMode == 'grid' ? colors.primary : colors.textDim),
                                  onPressed: () => setState(() => viewMode = 'grid'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search Bar (Glass)
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        borderRadius: 16,
                        colors: colors, // ✅ 傳入 S-FLOW Colors
                        child: TextField(
                          style: TextStyle(color: colors.text),
                          decoration: InputDecoration(
                            hintText: '搜尋搭配、標籤、品牌、用戶…',
                            hintStyle: TextStyle(color: colors.textDim),
                            border: InputBorder.none,
                            icon: Icon(Icons.search, color: colors.secondary),
                          ),
                          onChanged: (v) => setState(() => searchQuery = v),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Content
                      if (outfits.isEmpty)
                         Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(child: Text('暫無穿搭分享', style: TextStyle(color: colors.textDim))),
                        )
                      else if (viewMode == 'masonry')
                        MasonryGridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: w > 900 ? 3 : 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          itemCount: _display.length,
                          itemBuilder: (_, i) => _GlassOutfitCard(
                            outfit: _display[i],
                            colors: colors,
                            onTap: () => _openDetail(_display[i]),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: w > 900 ? 3 : 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _display.length,
                          itemBuilder: (_, i) => _GlassOutfitCard(
                            outfit: _display[i],
                            colors: colors,
                            onTap: () => _openDetail(_display[i]),
                          ),
                        ),

                      if (_display.isEmpty && outfits.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('找不到相關穿搭', style: TextStyle(color: colors.textDim))),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ----------------------------------------------------------------
// S-FLOW Local Components (保持與 S-FLOW colors 連動)
// ----------------------------------------------------------------

class _GlassTab extends StatelessWidget {
  final String label;
  final bool active;
  final SFlowColors colors;
  final VoidCallback onTap;

  const _GlassTab({required this.label, required this.active, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? colors.primary.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: active ? colors.primary : Colors.white10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: active ? colors.primary : colors.textDim, 
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _GlassOutfitCard extends StatelessWidget {
  final Outfit outfit;
  final SFlowColors colors;
  final VoidCallback onTap;

  const _GlassOutfitCard({required this.outfit, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: EdgeInsets.zero,
        colors: colors, // ✅ 使用傳入的顏色
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: outfit.aspect,
              child: Container(
                color: Colors.black26,
                child: outfit.imageUrl != null && outfit.imageUrl!.isNotEmpty
                    ? Image.network(
                        outfit.imageUrl!, 
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: colors.textDim),
                      )
                    : Icon(Icons.image, color: colors.textDim),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.description, 
                    style: TextStyle(color: colors.text, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10, 
                        backgroundColor: colors.glassBorder,
                        child: Text(outfit.userName.substring(0,1), style: TextStyle(fontSize: 10, color: colors.text)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(outfit.userName, style: TextStyle(color: colors.textDim, fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                      Icon(
                        outfit.isLiked ? Icons.favorite : Icons.favorite_border, 
                        size: 14, 
                        color: outfit.isLiked ? Colors.pinkAccent : colors.textDim
                      ),
                      const SizedBox(width: 4),
                      Text('${outfit.likes}', style: TextStyle(color: colors.textDim, fontSize: 11)),
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

class _GlassCommentSheet extends StatefulWidget {
  final Outfit outfit;
  final SFlowColors colors;
  final VoidCallback onLikeToggle;

  const _GlassCommentSheet({required this.outfit, required this.colors, required this.onLikeToggle});

  @override
  State<_GlassCommentSheet> createState() => _GlassCommentSheetState();
}

class _GlassCommentSheetState extends State<_GlassCommentSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  List<Comment> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final list = await ApiClient.I.getComments(widget.outfit.id);
      if (mounted) {
        setState(() {
          _comments = list.map((j) => Comment.fromJson(j)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _commentCtrl.clear();
    final tempComment = Comment(id: 'temp', userName: '我', text: text);
    setState(() => _comments.add(tempComment));
    try {
      await ApiClient.I.postComment(widget.outfit.id, text);
      _loadComments();
    } catch (e) {
      setState(() => _comments.remove(tempComment));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('留言失敗')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final outfit = widget.outfit;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GlassContainer(
      borderRadius: 24,
      colors: colors, // ✅ Sheet 背景也連動主題色
      padding: EdgeInsets.zero,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5), 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: outfit.aspect,
                      child: outfit.imageUrl != null 
                        ? Image.network(outfit.imageUrl!, fit: BoxFit.cover)
                        : Container(color: Colors.white10, child: Icon(Icons.image, size: 48, color: colors.textDim)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: colors.primary, child: Text(outfit.userName[0], style: const TextStyle(color: Colors.black))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(outfit.userName, style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16))),
                      IconButton(
                        onPressed: () {
                          setState(() {
                             outfit.isLiked = !outfit.isLiked;
                             outfit.likes += outfit.isLiked ? 1 : -1;
                          });
                          widget.onLikeToggle();
                        },
                        icon: Icon(outfit.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent),
                      ),
                      Text('${outfit.likes}', style: TextStyle(color: colors.textDim)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(outfit.description, style: TextStyle(color: colors.text.withOpacity(0.9), height: 1.5)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: outfit.tags.map((t) => Chip(
                      label: Text(t, style: TextStyle(color: colors.text, fontSize: 11)),
                      backgroundColor: Colors.white10,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                  if (outfit.items.isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 32),
                    Text('使用單品', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: outfit.items.map((item) => Chip(
                        avatar: const Icon(Icons.checkroom, size: 14, color: Colors.black),
                        label: Text('${item.brand} ${item.name}', style: const TextStyle(color: Colors.black, fontSize: 11)),
                        backgroundColor: colors.primary.withOpacity(0.8), // ✅ 使用 Primary Color
                      )).toList(),
                    ),
                  ],
                  const Divider(color: Colors.white10, height: 32),
                  Text('留言', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_loading) 
                    const Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    Text('成為第一個留言的人吧！', style: TextStyle(color: colors.textDim)),
                  
                  ..._comments.map((c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(radius: 14, backgroundColor: Colors.white10, child: Text(c.userName[0], style: TextStyle(color: colors.text))),
                    title: Text(c.userName, style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(c.text, style: TextStyle(color: colors.textDim)),
                  )),
                  SizedBox(height: 60 + bottomInset),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
                color: Colors.black45,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      style: TextStyle(color: colors.text),
                      decoration: InputDecoration(
                        hintText: '留言...',
                        hintStyle: TextStyle(color: colors.textDim),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white10,
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: Icon(Icons.send, color: colors.primary), onPressed: _sendComment),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}