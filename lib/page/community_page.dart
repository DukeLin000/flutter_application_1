import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_application_1/api/api_client.dart';

// 引用衣櫃模型 (為了使用 ClothingItem 類別)
import 'package:flutter_application_1/page/wardrobe_page.dart' as wardrobe;
// 引用衣物選擇器
import 'package:flutter_application_1/widgets/wardrobe_picker.dart';
// 引用新增穿搭的對話框
import 'package:flutter_application_1/widgets/ui/add_outfit_dialog.dart';

/// -----------------------------
/// Models (對接後端)
/// -----------------------------
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
  final double aspect; // image aspect ratio for masonry variance
  int likes;
  bool isLiked;
  final String? imageUrl; // 新增：穿搭圖片網址

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

  // ✅ Factory: 解析後端 OutfitDto JSON
  factory Outfit.fromJson(Map<String, dynamic> json) {
    // 解析關聯的單品列表
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
      aspect: 1.0, // 若後端有存長寬比可在此讀取，目前預設 1.0
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

/// -----------------------------
/// Community Page (RWD)
/// -----------------------------
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<Outfit> outfits = [];
  String activeTab = 'latest';
  String viewMode = 'masonry';
  String searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOutfits();
  }

  // 讀取穿搭列表
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
          SnackBar(content: Text('載入失敗: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ 核心流程：新增穿搭
  Future<void> _startAddOutfitFlow() async {
    // 步驟 1: 開啟衣物選擇器 (WardrobePicker)
    final selectedItems = await Navigator.push<List<wardrobe.ClothingItem>>(
      context,
      MaterialPageRoute(builder: (_) => const WardrobePicker()),
    );

    // 如果使用者沒選或是按返回，selectedItems 會是 null 或空
    if (selectedItems == null || selectedItems.isEmpty) return;

    if (!mounted) return;

    // 步驟 2: 開啟填寫資訊對話框 (AddOutfitDialog)
    await showDialog(
      context: context,
      builder: (_) => AddOutfitDialog(
        onSubmit: (formData) async {
          // 步驟 3: 呼叫後端 API 建立穿搭
          try {
            // 組裝要傳給後端的資料
            final outfitData = {
              'description': formData.description,
              'imageUrl': formData.imageUrl,
              'tags': formData.tags,
              // 將選中的單品 ID 列表傳送給後端
              'itemIds': selectedItems.map((i) => i.id).toList(),
            };

            await ApiClient.I.createOutfit(outfitData);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('發布成功！')),
              );
              _fetchOutfits(); // 成功後重新整理列表
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('發布失敗: $e')),
              );
            }
          }
        },
      ),
    );
  }

  // ✅ 按讚 / 取消按讚邏輯
  Future<void> _handleLike(String id) async {
    final idx = outfits.indexWhere((o) => o.id == id);
    if (idx < 0) return;

    final item = outfits[idx];
    // 樂觀更新 UI (先變色再送 API)
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
      // 失敗則回滾狀態
      if (!mounted) return;
      setState(() {
        item.isLiked = !item.isLiked;
        item.likes += item.isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失敗，請檢查網路')),
      );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('篩選（示範）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: const [
              Chip(label: Text('街頭')),
              Chip(label: Text('上班族')),
              Chip(label: Text('戶外'))
            ]),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('套用'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 開啟詳情與留言 Sheet
  void _openDetail(Outfit outfit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CommentSheet(
        outfit: outfit,
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
  bool _isMd(double w) => w >= 900;

  int _columns(double w) {
    if (w >= 1600) return 5;
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    if (w >= 600) return 2;
    return 1;
  }

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
    final isMd = _isMd(w);

    return Scaffold(
      appBar: AppBar(
        title: const Text('穿搭社群'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOutfits,
            tooltip: '重新整理',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final q = await showSearch<String?>(
                context: context,
                delegate: _OutfitSearchDelegate(
                  initial: searchQuery,
                  data: outfits,
                ),
              );
              if (q != null) setState(() => searchQuery = q);
            },
          ),
          // ✅ 連接新增流程
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增穿搭分享',
            onPressed: _startAddOutfitFlow,
          ),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      isLg ? 24 : 16, 16, isLg ? 24 : 16, isLg ? 24 : 88),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Tabs(
                            active: activeTab,
                            onChanged: (v) => setState(() => activeTab = v),
                            showFollowing: isMd,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLg)
                                OutlinedButton.icon(
                                  onPressed: _showFilterSheet,
                                  icon: const Icon(Icons.filter_alt_outlined, size: 18),
                                  label: const Text('篩選'),
                                ),
                              if (isLg) const SizedBox(width: 8),
                              if (isLg)
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).dividerColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  child: Row(
                                    children: [
                                      _ModeBtn(
                                        selected: viewMode == 'masonry',
                                        tooltip: '瀑布流',
                                        icon: Icons.grid_view,
                                        onTap: () => setState(() => viewMode = 'masonry'),
                                      ),
                                      const SizedBox(width: 4),
                                      _ModeBtn(
                                        selected: viewMode == 'grid',
                                        tooltip: '網格',
                                        icon: Icons.grid_on,
                                        onTap: () => setState(() => viewMode = 'grid'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (!isLg)
                        TextField(
                          decoration: InputDecoration(
                            hintText: '搜尋搭配、標籤、品牌、用戶…',
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (v) => setState(() => searchQuery = v),
                        ),
                      if (!isLg) const SizedBox(height: 12),

                      if (outfits.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: Text('暫無穿搭分享')),
                        )
                      else if (viewMode == 'masonry')
                        MasonryGridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: _columns(w),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          itemCount: _display.length,
                          itemBuilder: (_, i) => _OutfitCard(
                            outfit: _display[i],
                            onTap: () => _openDetail(_display[i]),
                            onLike: () => _handleLike(_display[i].id),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _columns(w),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 4 / 3,
                          ),
                          itemCount: _display.length,
                          itemBuilder: (_, i) => _OutfitCard(
                            outfit: _display[i],
                            onTap: () => _openDetail(_display[i]),
                            onLike: () => _handleLike(_display[i].id),
                          ),
                        ),

                      if (_display.isEmpty && outfits.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              '找不到相關穿搭',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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

/// -----------------------------
/// 獨立元件：留言與詳情 Sheet (已對接 API)
/// -----------------------------
class _CommentSheet extends StatefulWidget {
  final Outfit outfit;
  final VoidCallback onLikeToggle;
  const _CommentSheet({required this.outfit, required this.onLikeToggle});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
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

    FocusScope.of(context).unfocus(); // 收鍵盤
    _commentCtrl.clear();

    // 樂觀更新 UI
    final tempComment = Comment(id: 'temp', userName: '我', text: text);
    setState(() => _comments.add(tempComment));

    try {
      await ApiClient.I.postComment(widget.outfit.id, text);
      _loadComments(); // 重新拉取以取得正確 ID
    } catch (e) {
      setState(() => _comments.remove(tempComment)); // 失敗回滾
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('留言失敗')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.6,
      builder: (_, scrollController) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),
                  _OutfitHero(outfit: widget.outfit),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(child: Text(widget.outfit.userName.substring(0, 1))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.outfit.userName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            widget.outfit.isLiked = !widget.outfit.isLiked;
                            widget.outfit.likes += widget.outfit.isLiked ? 1 : -1;
                          });
                          widget.onLikeToggle();
                        },
                        icon: Icon(widget.outfit.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.pink),
                      ),
                      Text('${widget.outfit.likes}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.outfit.description),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final t in widget.outfit.tags) Chip(label: Text(t))]),

                  if (widget.outfit.items.isNotEmpty) ...[
                    const Divider(),
                    const Text('使用單品', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.outfit.items.map((item) => Chip(
                            avatar: const Icon(Icons.checkroom, size: 16),
                            label: Text('${item.brand} ${item.name}'),
                            backgroundColor: Colors.grey.shade100,
                          )).toList(),
                    ),
                  ],

                  const Divider(),
                  const Text('留言', style: TextStyle(fontWeight: FontWeight.w600)),
                  if (_loading)
                    const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                  else if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('成為第一個留言的人吧！', style: TextStyle(color: Colors.grey)),
                    ),

                  for (final c in _comments)
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(radius: 14, child: Text(c.userName.substring(0, 1), style: const TextStyle(fontSize: 12))),
                      title: Text(c.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(c.text),
                    ),

                  SizedBox(height: 24 + bottomInset), // 避免被輸入框擋住
                ],
              ),
            ),

            // 底部輸入框
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: '留言...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _sendComment),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// -----------------------------
/// UI Parts
/// -----------------------------
class _Tabs extends StatelessWidget {
  const _Tabs({required this.active, required this.onChanged, this.showFollowing = true});
  final String active;
  final ValueChanged<String> onChanged;
  final bool showFollowing;

  @override
  Widget build(BuildContext context) {
    Widget chip(String value, IconData? icon, String label) {
      final selected = active == value;
      return ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: 16),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onChanged(value),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: [
      chip('latest', Icons.home_outlined, '最新'),
      chip('trending', Icons.trending_up, '熱門'),
      if (showFollowing) chip('following', null, '追蹤中'),
    ]);
  }
}

class _ModeBtn extends StatelessWidget {
  const _ModeBtn({required this.selected, required this.tooltip, required this.icon, required this.onTap});
  final bool selected;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Icon(icon, size: 18),
          ),
        ),
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({required this.outfit, required this.onTap, required this.onLike});
  final Outfit outfit;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: outfit.aspect,
              child: outfit.imageUrl != null && outfit.imageUrl!.isNotEmpty
                  ? Image.network(outfit.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.error)))
                  : Container(
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
                  Row(
                    children: [
                      CircleAvatar(radius: 12, child: Text(outfit.userName.substring(0, 1))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(outfit.userName, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                      IconButton(
                        icon: Icon(outfit.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.pink),
                        onPressed: onLike,
                        visualDensity: VisualDensity.compact,
                      ),
                      Text('${outfit.likes}', style: t.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(outfit.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in outfit.tags)
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

class _OutfitHero extends StatelessWidget {
  const _OutfitHero({required this.outfit});
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: outfit.aspect,
            child: outfit.imageUrl != null && outfit.imageUrl!.isNotEmpty
                ? Image.network(outfit.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]))
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.checkroom_outlined, size: 100, color: Colors.black54),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outfit.description, style: t.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final tag in outfit.tags) Chip(label: Text(tag))]),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile(this.c);
  final Comment c;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(child: Text(c.userName.substring(0, 1))),
      title: Text(c.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(c.text),
    );
  }
}

/// -----------------------------
/// Search Delegate (for showSearch)
/// -----------------------------
class _OutfitSearchDelegate extends SearchDelegate<String?> {
  _OutfitSearchDelegate({required String initial, required this.data})
      : super(
          searchFieldLabel: '搜尋搭配、標籤、品牌、用戶…',
          textInputAction: TextInputAction.search,
        ) {
    query = initial;
  }

  final List<Outfit> data;

  List<Outfit> _matches(String q) {
    if (q.trim().isEmpty) return data.take(10).toList();
    final qq = q.toLowerCase();
    return data.where((o) {
      return o.description.toLowerCase().contains(qq) ||
          o.tags.any((t) => t.toLowerCase().contains(qq)) ||
          o.userName.toLowerCase().contains(qq) ||
          o.items.any((it) => it.brand.toLowerCase().contains(qq));
    }).toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildSuggestions(BuildContext context) {
    final m = _matches(query);
    return ListView.builder(
      itemCount: m.length,
      itemBuilder: (_, i) {
        final o = m[i];
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(o.description, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('@${o.userName} · ${o.tags.join(" / ")}'),
          onTap: () {
            close(context, query.isEmpty ? (o.tags.isNotEmpty ? o.tags.first : o.userName) : query);
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.search),
        label: Text('使用「$query」搜尋'),
        onPressed: () => close(context, query),
      ),
    );
  }
}