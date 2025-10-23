import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// -----------------------------
/// Models & Mock Data
/// -----------------------------
class OutfitItem {final String brand; final String name; const OutfitItem(this.brand, this.name);} 

class Outfit {
  final String id;
  final String userName;
  final String description;
  final List<String> tags;
  final List<OutfitItem> items;
  final double aspect; // image aspect ratio for masonry variance
  int likes;
  bool isLiked;
  Outfit({
    required this.id,
    required this.userName,
    required this.description,
    required this.tags,
    required this.items,
    this.aspect = 4/3,
    this.likes = 0,
    this.isLiked = false,
  });
}

class Comment {final String user; final String text; const Comment(this.user, this.text);} 

final Map<String, List<Comment>> mockComments = {
  'o1': const [Comment('Allen','外套配色好看!'), Comment('Becky','工裝褲版型不錯')],
  'o2': const [Comment('Cindy','上班穿這套剛好'), Comment('Davis','針織衫質感讚')],
  'o3': const [Comment('Erik','顏色超搭'), Comment('Finn','鞋子哪個牌子?')],
  'o4': const [Comment('Gigi','超喜歡這件大學T')],
};

final List<Outfit> mockOutfits = [
  Outfit(
    id:'o1', userName:'Rio',
    description:'機能外套 + 寬版褲，抗風又防潑水，今天微涼超適合',
    tags:['戶外','防潑水','街頭'],
    items:[const OutfitItem('Arc','Shell'), const OutfitItem('Uniqlo','Wide Pants')],
    aspect: 4/3, likes: 128,
  ),
  Outfit(
    id:'o2', userName:'Mia',
    description:'針織衫 + 直筒褲，通勤日常穿搭',
    tags:['上班族','舒適'],
    items:[const OutfitItem('COS','Knit'), const OutfitItem('Levis','501')],
    aspect: 1,
    likes: 86,
  ),
  Outfit(
    id:'o3', userName:'Ken',
    description:'連帽T + 工裝褲 + 老帽，休閒街頭感',
    tags:['街頭','保暖'],
    items:[const OutfitItem('Carhartt','Hoodie'), const OutfitItem('Dickies','Work Pants')],
    aspect: 3/4,
    likes: 205,
  ),
  Outfit(
    id:'o4', userName:'Zoe',
    description:'襯衫外搭針織背心，內搭白T，簡約層次',
    tags:['學院','層次'],
    items:[const OutfitItem('MUJI','Shirt'), const OutfitItem('GU','Vest')],
    aspect: 0.9,
    likes: 54,
  ),
  Outfit(
    id:'o5', userName:'Ian',
    description:'丹寧外套 + 軍綠寬褲，顏色協調',
    tags:['休閒','丹寧'],
    items:[const OutfitItem('Levis','Trucker'), const OutfitItem('WTAPS','Wide Cargo')],
    aspect: 1.2,
    likes: 73,
  ),
];

/// -----------------------------
/// Community Page (RWD)
/// -----------------------------
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late List<Outfit> outfits;
  String activeTab = 'latest';
  String viewMode = 'masonry'; // 'masonry' | 'grid'
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    outfits = [...mockOutfits];
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

  // ------------------ Actions ------------------
  void _handleLike(String id) {
    setState(() {
      final idx = outfits.indexWhere((o) => o.id == id);
      if (idx >= 0) {
        final o = outfits[idx];
        o.isLiked = !o.isLiked;
        o.likes += o.isLiked ? 1 : -1;
      }
    });
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
            Wrap(spacing: 8, children: const [Chip(label: Text('街頭')), Chip(label: Text('上班族')), Chip(label: Text('戶外'))]),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('套用')),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(Outfit outfit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.6,
        builder: (_, controller) {
          final comments = mockComments[outfit.id] ?? const <Comment>[];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              controller: controller,
              children: [
                const SizedBox(height: 8),
                _OutfitHero(outfit: outfit),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(child: Text(outfit.userName.substring(0,1)) ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(outfit.userName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    IconButton(
                      onPressed: () => setState(() => _handleLike(outfit.id)),
                      icon: Icon(outfit.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.pink),
                    ),
                    Text('${outfit.likes}')
                  ],
                ),
                const SizedBox(height: 8),
                Text(outfit.description),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final t in outfit.tags) Chip(label: Text(t))]),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('留言', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                for (final c in comments) _CommentTile(c),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------ Derived data ------------------
  List<Outfit> get _filtered {
    if (searchQuery.trim().isEmpty) return [...outfits];
    final q = searchQuery.toLowerCase();
    return outfits.where((o) {
      return o.description.toLowerCase().contains(q)
          || o.tags.any((t) => t.toLowerCase().contains(q))
          || o.userName.toLowerCase().contains(q)
          || o.items.any((it) => it.brand.toLowerCase().contains(q));
    }).toList();
  }

  List<Outfit> get _display {
    final list = [..._filtered];
    if (activeTab == 'trending') {
      list.sort((a, b) => b.likes.compareTo(a.likes));
    }
    // following: demo同 latest
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
          IconButton(icon: const Icon(Icons.search), onPressed: () async {
            final q = await showSearch<String?>(
            context: context,
            delegate: _OutfitSearchDelegate(
              initial: searchQuery,
              data: outfits,
            ),
          );
            if (q != null) setState(() => searchQuery = q);
          }),
          IconButton(icon: const Icon(Icons.add), onPressed: (){}),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: (){}),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(isLg ? 24 : 16, 16, isLg ? 24 : 16, isLg ? 24 : 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tabs + actions row
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Tabs(
                      active: activeTab,
                      onChanged: (v) => setState(() => activeTab = v),
                      showFollowing: isMd, // 追蹤中：md 以上才顯示
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

                // Search field (inline) for smaller screens
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

                // Grid / Masonry
                if (viewMode == 'masonry')
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
                      childAspectRatio: 4/3,
                    ),
                    itemCount: _display.length,
                    itemBuilder: (_, i) => _OutfitCard(
                      outfit: _display[i],
                      onTap: () => _openDetail(_display[i]),
                      onLike: () => _handleLike(_display[i].id),
                    ),
                  ),

                if (_display.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('找不到相關穿搭', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
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
/// UI Parts
/// -----------------------------
class _Tabs extends StatelessWidget {
  const _Tabs({required this.active, required this.onChanged, this.showFollowing = true});
  final String active; final ValueChanged<String> onChanged; final bool showFollowing;
  @override
  Widget build(BuildContext context) {
    Widget chip(String value, IconData? icon, String label, {bool hideOnSmall = false}) {
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
  final bool selected; final String tooltip; final IconData icon; final VoidCallback onTap;
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
  final Outfit outfit; final VoidCallback onTap; final VoidCallback onLike;
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
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                      CircleAvatar(radius: 12, child: Text(outfit.userName.substring(0,1))),
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
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final tag in outfit.tags) Chip(label: Text(tag), visualDensity: VisualDensity.compact)]),
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
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
      leading: CircleAvatar(child: Text(c.user.substring(0,1))),
      title: Text(c.user, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

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
            close(context, query.isEmpty
                ? (o.tags.isNotEmpty ? o.tags.first : o.userName)
                : query);
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

