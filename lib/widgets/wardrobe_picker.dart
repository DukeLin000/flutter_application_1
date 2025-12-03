import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_client.dart';
// 引用 WardrobePage 是為了使用裡面的 ClothingItem 模型定義
// 這樣我們就不用重複寫 class ClothingItem
import 'package:flutter_application_1/page/wardrobe_page.dart'; 

class WardrobePicker extends StatefulWidget {
  const WardrobePicker({super.key});

  @override
  State<WardrobePicker> createState() => _WardrobePickerState();
}

class _WardrobePickerState extends State<WardrobePicker> {
  List<ClothingItem> _items = [];
  final Set<String> _selectedIds = {}; // 記錄選了哪些衣服的 ID
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final list = await ApiClient.I.listItems();
      if (mounted) {
        setState(() {
          // 使用 ClothingItem.fromJson 將資料轉為物件
          _items = list.map((json) => ClothingItem.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('錯誤: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇搭配單品'),
        actions: [
          TextButton(
            // 如果沒選任何衣服，按鈕失效
            onPressed: _selectedIds.isEmpty
                ? null
                : () {
                    // 篩選出被選中的 ClothingItem 物件，並回傳給上一頁
                    final selectedItems = _items
                        .where((i) => _selectedIds.contains(i.id))
                        .toList();
                    Navigator.pop(context, selectedItems);
                  },
            child: Text(
              '下一步 (${_selectedIds.length})',
              style: TextStyle(
                color: _selectedIds.isEmpty ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('衣櫃空空的，先去新增衣服吧！'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final item = _items[i];
                    final isSelected = _selectedIds.contains(item.id);
                    
                    return InkWell(
                      onTap: () {
                        // 點擊切換勾選狀態
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(item.id);
                          } else {
                            _selectedIds.add(item.id);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          // 選中時顯示藍色邊框
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 3)
                              : Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // 顯示圖片
                                  item.imageUrl.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_,__,___) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                                        )
                                      : Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                                  
                                  // 選中時顯示右上角勾勾
                                  if (isSelected)
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Container(
                                        color: Colors.white.withOpacity(0.5),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.check_circle, color: Colors.blue, size: 24),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                item.subCategory,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}