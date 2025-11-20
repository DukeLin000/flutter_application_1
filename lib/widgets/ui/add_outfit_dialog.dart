import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Model：回傳給上層使用的表單資料
/// ---------------------------------------------------------------------------
class OutfitItem {
  final String brand;
  final String category;

  const OutfitItem({
    required this.brand,
    required this.category,
  });
}

class AddOutfitFormData {
  final String imageUrl;
  final String description;
  final List<String> tags;
  final List<OutfitItem> items;

  const AddOutfitFormData({
    required this.imageUrl,
    required this.description,
    required this.tags,
    required this.items,
  });
}

/// ---------------------------------------------------------------------------
/// AddOutfitDialog：新增穿搭 Dialog（RWD）
/// 使用方式：
/// showDialog(
///   context: context,
///   builder: (_) => AddOutfitDialog(
///     onSubmit: (data) {
///       // 呼叫後端 API 或更新畫面
///     },
///   ),
/// );
/// ---------------------------------------------------------------------------
class AddOutfitDialog extends StatefulWidget {
  final void Function(AddOutfitFormData data) onSubmit;
  final VoidCallback? onClose;

  const AddOutfitDialog({
    super.key,
    required this.onSubmit,
    this.onClose,
  });

  @override
  State<AddOutfitDialog> createState() => _AddOutfitDialogState();
}

class _AddOutfitDialogState extends State<AddOutfitDialog> {
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  final List<String> _suggestedTags = const [
    '街頭',
    '休閒',
    '正式',
    '約會',
    '運動',
    '日系',
    '韓系',
    '極簡',
    '復古',
    '工裝',
  ];

  final List<String> _selectedTags = [];
  final List<OutfitItem> _items = [];

  bool _imageLoadFailed = false;

  @override
  void dispose() {
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleAddTag([String? value]) {
    final tag = (value ?? _tagInputController.text).trim();
    if (tag.isEmpty) return;
    if (_selectedTags.contains(tag)) return;

    setState(() {
      _selectedTags.add(tag);
      _tagInputController.clear();
    });
  }

  void _handleRemoveTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  void _handleAddItem() {
    final brand = _brandController.text.trim();
    final category = _categoryController.text.trim();
    if (brand.isEmpty || category.isEmpty) return;

    setState(() {
      _items.add(OutfitItem(brand: brand, category: category));
      _brandController.clear();
      _categoryController.clear();
    });
  }

  void _handleRemoveItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _handleSubmit() {
    final imageUrl = _imageUrlController.text.trim();
    final description = _descriptionController.text.trim();

    if (imageUrl.isEmpty) {
      _showSnack('請輸入圖片網址');
      return;
    }
    if (description.isEmpty) {
      _showSnack('請輸入穿搭描述');
      return;
    }

    final data = AddOutfitFormData(
      imageUrl: imageUrl,
      description: description,
      tags: List<String>.unmodifiable(_selectedTags),
      items: List<OutfitItem>.unmodifiable(_items),
    );

    widget.onSubmit(data);

    Navigator.of(context).pop();
    widget.onClose?.call();

    _showSnack('穿搭已發布！');
  }

  void _handleCancel() {
    Navigator.of(context).pop();
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isWide = media.size.width >= 600;

    final double maxWidth = isWide ? 640.0 : media.size.width * 0.98;
    final double maxHeight = media.size.height * 0.9;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 24.0 : 12.0,
        vertical: 24.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _buildHeader(),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageSection(),
                        const SizedBox(height: 16),
                        _buildDescriptionSection(),
                        const SizedBox(height: 16),
                        _buildTagSection(),
                        const SizedBox(height: 16),
                        _buildItemsSection(constraints.maxWidth),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleCancel,
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          child: const Text('發布穿搭'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// Header
  /// -------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '新增穿搭',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleCancel,
            tooltip: '關閉',
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 圖片區
  /// -------------------------------------------------------------------------
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.image_outlined, size: 18),
            SizedBox(width: 8),
            Text(
              '穿搭圖片',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _imageUrlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: '輸入圖片網址（https://...）',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) {
            // 使用者改了網址，重新嘗試載入
            if (_imageLoadFailed) {
              setState(() {
                _imageLoadFailed = false;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        if (_imageUrlController.text.isNotEmpty && !_imageLoadFailed)
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.network(
                  _imageUrlController.text,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    if (!_imageLoadFailed) {
                      _imageLoadFailed = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showSnack('圖片載入失敗，請檢查網址');
                      });
                    }
                    return Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Text(
                        '圖片載入失敗',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// 描述區
  /// -------------------------------------------------------------------------
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.notes_outlined, size: 18),
            SizedBox(width: 8),
            Text(
              '描述',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '分享你的穿搭靈感、搭配心得...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// 標籤區
  /// -------------------------------------------------------------------------
  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.local_offer_outlined, size: 18),
            SizedBox(width: 8),
            Text(
              '標籤',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 建議標籤
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedTags.map((tag) {
            final bool selected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: selected,
              onSelected: (_) {
                if (selected) {
                  _handleRemoveTag(tag);
                } else {
                  _handleAddTag(tag);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // 自訂標籤輸入
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagInputController,
                decoration: const InputDecoration(
                  hintText: '自訂標籤（按 Enter 或按右側新增）',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: _handleAddTag,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _handleAddTag,
              child: const Text('新增'),
            ),
          ],
        ),
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _handleRemoveTag(tag),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// 單品資訊區
  /// -------------------------------------------------------------------------
  Widget _buildItemsSection(double maxWidth) {
    final bool isWide = maxWidth >= 480;

    Widget inputRow = isWide
        ? Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    hintText: '品牌（例如：Uniqlo）',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    hintText: '類別（例如：上衣）',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: _handleAddItem,
                  child: const Text('新增'),
                ),
              ),
            ],
          )
        : Column(
            children: [
              TextField(
                controller: _brandController,
                decoration: const InputDecoration(
                  hintText: '品牌（例如：Uniqlo）',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  hintText: '類別（例如：上衣）',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: _handleAddItem,
                    child: const Text('新增'),
                  ),
                ),
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '單品資訊（選填）',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        inputRow,
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Column(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.brand} - ${item.category}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _handleRemoveItem(index),
                      color: Colors.grey.shade500,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
