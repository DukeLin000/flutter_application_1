// lib/widgets/add_item_dialog.dart
// Camera permission–aware version (Android/iOS) with safe Web fallback
// -------------------------------------------------------------------
// Platform setup (once):
// - pubspec.yaml:  permission_handler: ^12.0.1 , image_picker: ^1.x , file_picker: ^8.x
// - Android:  AndroidManifest.xml
//     <uses-permission android:name="android.permission.CAMERA"/>
// - iOS: Info.plist
//     <key>NSCameraUsageDescription</key><string>需要使用相機上傳衣物照片</string>
//     <key>NSPhotoLibraryUsageDescription</key><string>需要讀取相簿選擇照片</string>
// - Web: 建議以 HTTPS 或 http://localhost 開發；瀏覽器會彈出相機權限對話框。

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:permission_handler/permission_handler.dart';

/// ==================== 資料模型（等價於 TS ClothingItem） ====================
enum Category { top, bottom, outerwear, shoes, accessory }
enum Season { spring, summer, fall, winter }
enum Occasion { casual, office, sport, formal }
enum Fit { slim, regular, loose }

class ClothingItem {
  final String id;
  final String imageUrl; // 可放遠端或 base64 data URL
  final Uint8List? imageBytes; // 選用：原始 bytes
  final Category category;
  final String subCategory;
  final String? brand;
  final List<String> color;
  final List<Season> season;
  final List<Occasion> occasion;
  final Fit fit;
  final bool waterproof;
  final int warmth; // 0..5
  final int breathability; // 0..5
  final bool isFavorite;
  final List<String> tags;

  ClothingItem({
    required this.id,
    required this.imageUrl,
    this.imageBytes,
    required this.category,
    required this.subCategory,
    this.brand,
    required this.color,
    required this.season,
    required this.occasion,
    required this.fit,
    required this.waterproof,
    required this.warmth,
    required this.breathability,
    this.isFavorite = false,
    this.tags = const [],
  });
}

/// 對齊 React：以 Dialog 方式開啟，回傳新增的 ClothingItem（或 null）
Future<ClothingItem?> showAddItemDialog(
  BuildContext context, {
  Category initialCategory = Category.top,
}) {
  return showDialog<ClothingItem>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AddItemDialog(initialCategory: initialCategory),
  );
}

/// ==================== Dialog 本體 ====================
class _AddItemDialog extends StatefulWidget {
  final Category initialCategory;
  const _AddItemDialog({required this.initialCategory});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  // 影像
  Uint8List? _imageBytes;

  // 表單狀態
  Category _category = Category.top;
  String _subCategory = '';
  final TextEditingController _brandCtrl = TextEditingController();
  final Set<String> _selectedColors = {};
  final Set<Season> _selectedSeasons = {};
  final Set<Occasion> _selectedOccasions = {};
  Fit _fit = Fit.regular;
  bool _waterproof = false;
  int _warmth = 2;
  int _breathability = 3;
  final List<String> _tags = [];
  final TextEditingController _tagCtrl = TextEditingController();

  // 選項（對齊你的 TS 常數）
  final List<Map<String, dynamic>> _categoryOptions = const [
    {'value': Category.top, 'label': '上衣'},
    {'value': Category.bottom, 'label': '下身'},
    {'value': Category.outerwear, 'label': '外套'},
    {'value': Category.shoes, 'label': '鞋子'},
    {'value': Category.accessory, 'label': '配件'},
  ];

  final Map<Category, List<String>> _subCategoryMap = const {
    Category.top: ['T恤', '襯衫', '帽T', '針織衫', 'Polo衫', '背心', '長袖上衣'],
    Category.bottom: ['牛仔褲', '休閒褲', '西裝褲', '短褲', '工裝褲', '運動褲', '卡其褲'],
    Category.outerwear: ['牛仔外套', '西裝外套', '大衣', '羽絨外套', '風衣', '教練外套', '夾克'],
    Category.shoes: ['球鞋', '皮鞋', '樂福鞋', '靴子', '涼鞋', '拖鞋', '帆布鞋'],
    Category.accessory: ['帽子', '圍巾', '手錶', '包包', '腰帶', '太陽眼鏡', '襪子'],
  };

  final List<String> _colorOptions = const [
    '黑色', '白色', '灰色', '米色', '藍色', '深藍', '紅色', '綠色', '黃色', '棕色', '卡其', '粉色', '紫色', '橘色'
  ];

  final List<Map<String, dynamic>> _seasonOptions = const [
    {'value': Season.spring, 'label': '春'},
    {'value': Season.summer, 'label': '夏'},
    {'value': Season.fall, 'label': '秋'},
    {'value': Season.winter, 'label': '冬'},
  ];

  final List<Map<String, dynamic>> _occasionOptions = const [
    {'value': Occasion.casual, 'label': '休閒'},
    {'value': Occasion.office, 'label': '辦公'},
    {'value': Occasion.sport, 'label': '運動'},
    {'value': Occasion.formal, 'label': '正式'},
  ];

  final List<Map<String, dynamic>> _fitOptions = const [
    {'value': Fit.slim, 'label': '修身'},
    {'value': Fit.regular, 'label': '標準'},
    {'value': Fit.loose, 'label': '寬鬆'},
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: err ? Colors.red : null),
    );
  }

  // -------------------- Permissions --------------------
  Future<bool> _ensureCameraPermission() async {
    if (kIsWeb) return true; // Web 交給瀏覽器處理

    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _toast('相機權限被永久拒絕，請至系統設定開啟');
      await openAppSettings();
      return false;
    }

    // iOS 可能是 restricted；Android 可能是 denied
    final result = await Permission.camera.request();
    if (result.isGranted) return true;

    _toast('未取得相機權限');
    return false;
  }

  // iOS 14+ 相簿權限（僅當使用 image_picker 讀相簿時有幫助）
  Future<bool> _ensurePhotosPermission() async {
    if (kIsWeb) return true;
    // 部分裝置不需要顯式申請，失敗時再提示即可
    final p = await Permission.photos.status;
    if (p.isGranted || p.isLimited || p.isDenied) return true; // 允許/局限/交給系統彈窗
    if (p.isPermanentlyDenied) {
      _toast('照片存取權限被永久拒絕，請至系統設定開啟');
      await openAppSettings();
      return false;
    }
    await Permission.photos.request();
    return true;
  }

  /// Web 用 file_picker；行動裝置/桌機 App 用 image_picker
  Future<void> _pickFromGallery() async {
    try {
      if (kIsWeb) {
        final res = await fp.FilePicker.platform.pickFiles(
          type: fp.FileType.image,
          withData: true,
        );
        if (res != null && res.files.single.bytes != null) {
          final b = res.files.single.bytes!;
          if (b.lengthInBytes > 5 * 1024 * 1024) {
            _toast('圖片大小不能超過 5MB', err: true);
            return;
          }
          setState(() => _imageBytes = b);
          _toast('圖片上傳成功');
        }
      } else {
        await _ensurePhotosPermission();
        final picker = ImagePicker();
        final x = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
          maxWidth: 4096,
        );
        if (x != null) {
          final b = await x.readAsBytes();
          if (b.lengthInBytes > 5 * 1024 * 1024) {
            _toast('圖片大小不能超過 5MB', err: true);
            return;
          }
          setState(() => _imageBytes = b);
          _toast('圖片上傳成功');
        }
      }
    } catch (_) {
      _toast('圖片上傳失敗', err: true);
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      if (kIsWeb) {
        // 瀏覽器會彈權限視窗；需 HTTPS 或 localhost
        final x = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
          maxWidth: 2048,
        );
        if (x == null) return;
        final b = await x.readAsBytes();
        if (b.lengthInBytes > 5 * 1024 * 1024) {
          _toast('圖片大小不能超過 5MB', err: true);
          return;
        }
        setState(() => _imageBytes = b);
        _toast('圖片上傳成功');
        return;
      }

      final ok = await _ensureCameraPermission();
      if (!ok) return;

      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear, // 正確：rear/front
        imageQuality: 90,
        maxWidth: 2048,
      );
      if (x != null) {
        final b = await x.readAsBytes();
        if (b.lengthInBytes > 5 * 1024 * 1024) {
          _toast('圖片大小不能超過 5MB', err: true);
          return;
        }
        setState(() => _imageBytes = b);
        _toast('圖片上傳成功');
      }
    } catch (_) {
      _toast('圖片上傳失敗', err: true);
    }
  }

  String _dataUrl(Uint8List bytes) => 'data:image/png;base64,${base64Encode(bytes)}';

  void _addTag() {
    final v = _tagCtrl.text.trim();
    if (v.isNotEmpty && !_tags.contains(v)) {
      setState(() {
        _tags.add(v);
        _tagCtrl.clear();
      });
    }
  }

  void _submit() {
    if (_subCategory.trim().isEmpty) {
      _toast('請輸入衣物名稱', err: true);
      return;
    }
    if (_selectedColors.isEmpty) {
      _toast('請至少選擇一個顏色', err: true);
      return;
    }
    if (_selectedSeasons.isEmpty) {
      _toast('請至少選擇一個季節', err: true);
      return;
    }
    if (_selectedOccasions.isEmpty) {
      _toast('請至少選擇一個場合', err: true);
      return;
    }

    final imageUrl = _imageBytes == null
        ? 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=400'
        : _dataUrl(_imageBytes!);

    final item = ClothingItem(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      imageUrl: imageUrl,
      imageBytes: _imageBytes,
      category: _category,
      subCategory: _subCategory.trim(),
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      color: _selectedColors.toList(),
      season: _selectedSeasons.toList(),
      occasion: _selectedOccasions.toList(),
      fit: _fit,
      waterproof: _waterproof,
      warmth: _warmth,
      breathability: _breathability,
      isFavorite: false,
      tags: List.of(_tags),
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final dialogW = w < 680 ? w * 0.95 : 720.0; // RWD：手機近滿版、桌機 720px

    return AlertDialog(
      title: const Text('新增衣物'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: SizedBox(
        width: dialogW,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('填寫以下資訊來新增一件衣物到你的衣櫃',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),

              // 圖片上傳
              _Section(
                title: '圖片（選填）',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickFromCamera,
                          icon: const Icon(Icons.photo_camera_outlined, size: 18),
                          label: const Text('拍照'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.upload_outlined, size: 18),
                          label: const Text('相簿'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_imageBytes != null)
                      Stack(
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12, width: 2),
                              color: Colors.grey.shade100,
                            ),
                            child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Material(
                              color: Colors.red.shade400,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => setState(() => _imageBytes = null),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // 類別
              _Section(
                title: '類別 *',
                child: DropdownButtonFormField<Category>(
                  value: _category,
                  items: _categoryOptions
                      .map((e) => DropdownMenuItem<Category>(
                            value: e['value'] as Category,
                            child: Text(e['label'] as String),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _category = v!;
                    _subCategory = '';
                  }),
                ),
              ),

              // 名稱 / 子類別快捷
              _Section(
                title: '名稱 *',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: _subCategory,
                      onChanged: (v) => setState(() => _subCategory = v),
                      decoration: const InputDecoration(
                        hintText: '例如：白色T恤、黑色牛仔褲',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _subCategoryMap[_category]!
                          .map((s) => ChoiceChip(
                                label: Text(s),
                                selected: _subCategory == s,
                                onSelected: (_) => setState(() => _subCategory = s),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              // 品牌
              _Section(
                title: '品牌（選填）',
                child: TextField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(hintText: '例如：UNIQLO、Zara'),
                ),
              ),

              // 顏色
              _Section(
                title: '顏色 *',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorOptions.map((c) {
                    final selected = _selectedColors.contains(c);
                    return FilterChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selected ? _selectedColors.remove(c) : _selectedColors.add(c);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              // 季節
              _Section(
                title: '適合季節 *',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _seasonOptions.map((e) {
                    final v = e['value'] as Season;
                    final selected = _selectedSeasons.contains(v);
                    return FilterChip(
                      label: Text(e['label'] as String),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selected ? _selectedSeasons.remove(v) : _selectedSeasons.add(v);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              // 場合
              _Section(
                title: '適合場合 *',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _occasionOptions.map((e) {
                    final v = e['value'] as Occasion;
                    final selected = _selectedOccasions.contains(v);
                    return FilterChip(
                      label: Text(e['label'] as String),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selected ? _selectedOccasions.remove(v) : _selectedOccasions.add(v);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              // 版型 / 防水
              _Section(
                title: '版型 / 防水',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: _fitOptions.map((e) {
                        final v = e['value'] as Fit;
                        return ChoiceChip(
                          label: Text(e['label'] as String),
                          selected: _fit == v,
                          onSelected: (_) => setState(() => _fit = v),
                        );
                      }).toList(),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _waterproof,
                      onChanged: (v) => setState(() => _waterproof = v),
                      title: const Text('防水功能'),
                    ),
                  ],
                ),
              ),

              // 保暖 / 透氣
              _Section(
                title: '保暖 / 透氣',
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('保暖'),
                        Expanded(
                          child: Slider(
                            value: _warmth.toDouble(),
                            min: 0,
                            max: 5,
                            divisions: 5,
                            label: '$_warmth',
                            onChanged: (d) => setState(() => _warmth = d.round()),
                          ),
                        ),
                        Text('$_warmth'),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('透氣'),
                        Expanded(
                          child: Slider(
                            value: _breathability.toDouble(),
                            min: 0,
                            max: 5,
                            divisions: 5,
                            label: '$_breathability',
                            onChanged: (d) => setState(() => _breathability = d.round()),
                          ),
                        ),
                        Text('$_breathability'),
                      ],
                    ),
                  ],
                ),
              ),

              // 標籤
              _Section(
                title: '標籤（選填）',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagCtrl,
                            onSubmitted: (_) => _addTag(),
                            decoration: const InputDecoration(hintText: '輸入後 Enter 加入'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: _addTag, child: const Text('加入')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: -6,
                      children: _tags
                          .map(
                            (t) => Chip(
                              label: Text(t),
                              onDeleted: () => setState(() => _tags.remove(t)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('新增'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 小段落容器
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
