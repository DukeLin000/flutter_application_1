import 'package:flutter/material.dart';

/// OnboardingPage (Flutter, fully responsive for Web, iOS, Android)
/// ------------------------------------------------------------------
/// Usage:
///   OnboardingPage(
///     onComplete: (profile) {
///       // TODO: handle completed profile
///     },
///   )
///
/// Notes:
/// - Pure Material widgets (no extra packages).
/// - Responsive layout via LayoutBuilder and max content width.
/// - Feature parity with the provided React version:
///   * Stepper (3 steps)
///   * Step 1: base info + gender/fit/commute
///   * Step 2: style selection dialog (default + custom) + color blacklist
///             （權重自動平均、未顯示滑桿 UI，依你的需求）
///   * Step 3: confirmation summary
/// - "Toast" equivalents use SnackBar.

// ---------------------------- Models & Helpers ----------------------------

class UserProfile {
  String gender; // 'male' | 'female' | 'other'
  int height; // cm
  int weight; // kg
  int shoulderWidth; // cm
  int waistline; // cm
  String fitPreference; // 'slim' | 'regular' | 'loose'
  List<String> colorBlacklist; // ["pink", "purple", ...]
  bool hasMotorcycle; // kept for parity (not shown separately in UI)
  String commuteMethod; // 'walk' | 'bike' | 'motorcycle' | 'car' | 'public'
  Map<String, int> styleWeights; // { street: 33, outdoor: 33, office: 34 }

  UserProfile({
    required this.gender,
    required this.height,
    required this.weight,
    required this.shoulderWidth,
    required this.waistline,
    required this.fitPreference,
    required this.colorBlacklist,
    required this.hasMotorcycle,
    required this.commuteMethod,
    required this.styleWeights,
  });

  Map<String, dynamic> toJson() => {
        'gender': gender,
        'height': height,
        'weight': weight,
        'shoulderWidth': shoulderWidth,
        'waistline': waistline,
        'fitPreference': fitPreference,
        'colorBlacklist': colorBlacklist,
        'hasMotorcycle': hasMotorcycle,
        'commuteMethod': commuteMethod,
        'styleWeights': styleWeights,
      };
}

class StyleOption {
  final String id; // e.g. 'street'
  final String label; // e.g. '街頭'
  final bool isCustom;
  const StyleOption({required this.id, required this.label, this.isCustom = false});
}

const List<StyleOption> kDefaultStyleOptions = <StyleOption>[
  StyleOption(id: 'street', label: '街頭'),
  StyleOption(id: 'outdoor', label: '戶外機能'),
  StyleOption(id: 'office', label: '上班族'),
  StyleOption(id: 'minimal', label: '極簡'),
  StyleOption(id: 'workwear', label: '工裝'),
  StyleOption(id: 'japanese', label: '日系'),
  StyleOption(id: 'korean', label: '韓系'),
  StyleOption(id: 'american', label: '美式'),
  StyleOption(id: 'sports', label: '運動'),
  StyleOption(id: 'casual', label: '休閒'),
  StyleOption(id: 'vintage', label: '復古'),
  StyleOption(id: 'dandy', label: '雅痞'),
  StyleOption(id: 'preppy', label: '學院'),
  StyleOption(id: 'biker', label: '機車/騎士'),
  StyleOption(id: 'military', label: '軍裝'),
  StyleOption(id: 'commute_business', label: '通勤商務'),
];

String generateCustomStyleId(String name) {
  final slug = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), '-');
  return 'custom-$slug';
}

String? validateCustomStyleName(String name, List<StyleOption> all) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '請輸入風格名稱';
  if (trimmed.length > 20) return '最多 20 個字元';
  final exists = all.any((s) => s.label == trimmed || s.id == generateCustomStyleId(trimmed));
  if (exists) return '此風格已存在';
  return null; // valid
}

Map<String, int> initializeStyleWeights(List<String> styleIds) {
  // Evenly distribute 100 across given styles; last gets remainder to ensure sum=100
  if (styleIds.isEmpty) return {};
  final base = (100 ~/ styleIds.length);
  int remainder = 100 - base * styleIds.length;
  final map = <String, int>{};
  for (int i = 0; i < styleIds.length; i++) {
    final w = base + (remainder > 0 ? 1 : 0);
    if (remainder > 0) remainder--;
    map[styleIds[i]] = w;
  }
  return map;
}

Map<String, int> convertSelectedStylesToWeights(List<String> styleIds) {
  return initializeStyleWeights(styleIds);
}

List<String> getSelectedStylesFromWeights(Map<String, int> weights) {
  return weights.entries.where((e) => (e.value) > 0).map((e) => e.key).toList();
}

Map<String, int> distributeEvenly(List<String> styleIds) => initializeStyleWeights(styleIds);

Map<String, int> clearAllWeights(Map<String, int> current) {
  return {for (final k in current.keys) k: 0};
}

int sumWeights(Map<String, int> weights) => weights.values.fold(0, (a, b) => a + b);

// ---------------------------- Main Widget ----------------------------

class OnboardingPage extends StatefulWidget {
  final ValueChanged<UserProfile> onComplete;
  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int step = 1;

  // Defaults
  final List<String> defaultStyleIds = const ['street', 'outdoor', 'office'];

  // State: profile
  late UserProfile profile;

  // Styles state
  late List<StyleOption> customStyles; // user-added
  late List<String> selectedStyleIds; // in the main screen (step 2)

  // Dialog temp selection
  bool isStyleDialogOpen = false; // maintained implicitly by showDialog
  late List<String> tempSelectedStyles;
  final TextEditingController newStyleCtrl = TextEditingController();

  // Colors blacklist
  final List<_ColorSwatch> availableColors = const [
    _ColorSwatch(id: 'pink', label: '粉紅', color: Colors.pinkAccent),
    _ColorSwatch(id: 'purple', label: '紫色', color: Colors.purpleAccent),
    _ColorSwatch(id: 'yellow', label: '黃色', color: Colors.amberAccent),
    _ColorSwatch(id: 'orange', label: '橘色', color: Colors.orangeAccent),
    _ColorSwatch(id: 'green', label: '綠色', color: Colors.lightGreen),
    _ColorSwatch(id: 'red', label: '紅色', color: Colors.redAccent),
  ];

  @override
  void initState() {
    super.initState();
    customStyles = <StyleOption>[];
    selectedStyleIds = List<String>.from(defaultStyleIds);
    tempSelectedStyles = List<String>.from(defaultStyleIds);

    profile = UserProfile(
      gender: 'male',
      height: 175,
      weight: 70,
      shoulderWidth: 45,
      waistline: 80,
      fitPreference: 'regular',
      colorBlacklist: <String>[],
      hasMotorcycle: false,
      commuteMethod: 'public',
      styleWeights: initializeStyleWeights(selectedStyleIds),
    );
  }

  @override
  void dispose() {
    newStyleCtrl.dispose();
    super.dispose();
  }

  // Convenience
  List<StyleOption> getAllStyleOptions() => [...kDefaultStyleOptions, ...customStyles];

  List<StyleOption> getDisplayedStyles() {
    final all = getAllStyleOptions();
    return all.where((s) => selectedStyleIds.contains(s.id)).toList();
  }

  void _handleOpenStyleDialog() {
    tempSelectedStyles = List<String>.from(selectedStyleIds);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final all = getAllStyleOptions();
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette_outlined),
                        const SizedBox(width: 8),
                        const Text('選擇您喜歡的風格', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          tooltip: '關閉',
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('點選標籤以加入/移除；您已選擇 ${tempSelectedStyles.length} 個風格',
                        style: Theme.of(context).textTheme.bodySmall),
                    const Divider(height: 24),

                    // Add custom style
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_outlined),
                        const SizedBox(width: 8),
                        const Text('新增自訂風格', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newStyleCtrl,
                            maxLength: 20,
                            decoration: const InputDecoration(
                              hintText: '輸入風格名稱（如：嘻哈、龐克）',
                              counterText: '',
                            ),
                            onSubmitted: (_) => _addCustomStyle(setLocal),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _addCustomStyle(setLocal),
                          icon: const Icon(Icons.add),
                          label: const Text('新增'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final style in all)
                              _SelectableBadge(
                                label: style.label,
                                selected: tempSelectedStyles.contains(style.id),
                                isCustom: style.isCustom,
                                onTap: () => setLocal(() {
                                  if (tempSelectedStyles.contains(style.id)) {
                                    tempSelectedStyles.remove(style.id);
                                  } else {
                                    tempSelectedStyles.add(style.id);
                                  }
                                }),
                                onDelete: style.isCustom
                                    ? () => setLocal(() {
                                          // delete custom style & deselect
                                          customStyles = customStyles.where((s) => s.id != style.id).toList();
                                          tempSelectedStyles.remove(style.id);
                                          selectedStyleIds.remove(style.id);
                                          // clear weight if exists
                                          final newWeights = {...profile.styleWeights};
                                          newWeights.remove(style.id);
                                          setState(() => profile = _profileWithWeights(newWeights));
                                        })
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 24),
                    Row(
                      children: [
                        Text('已選擇 ${tempSelectedStyles.length} 個風格',
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (tempSelectedStyles.isEmpty) {
                              // reset to defaults
                              setState(() {
                                selectedStyleIds = List<String>.from(defaultStyleIds);
                                profile = _profileWithWeights(initializeStyleWeights(selectedStyleIds));
                              });
                            } else {
                              setState(() {
                                selectedStyleIds = List<String>.from(tempSelectedStyles);
                                profile = _profileWithWeights(
                                  convertSelectedStylesToWeights(selectedStyleIds),
                                );
                              });
                            }
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('確認選擇'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _addCustomStyle(void Function(void Function()) setLocal) {
    final name = newStyleCtrl.text;
    final validation = validateCustomStyleName(name, getAllStyleOptions());
    if (validation != null) {
      _toast(validation);
      return;
    }
    final newStyle = StyleOption(id: generateCustomStyleId(name), label: name.trim(), isCustom: true);
    setLocal(() {
      customStyles = [...customStyles, newStyle];
      tempSelectedStyles.add(newStyle.id);
      newStyleCtrl.clear();
    });
    _toast('已新增風格「${newStyle.label}」');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  UserProfile _profileWithWeights(Map<String, int> newWeights) {
    return UserProfile(
      gender: profile.gender,
      height: profile.height,
      weight: profile.weight,
      shoulderWidth: profile.shoulderWidth,
      waistline: profile.waistline,
      fitPreference: profile.fitPreference,
      colorBlacklist: List<String>.from(profile.colorBlacklist),
      hasMotorcycle: profile.hasMotorcycle,
      commuteMethod: profile.commuteMethod,
      styleWeights: newWeights,
    );
  }

  // ---------------------------- UI Builders ----------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 600; // phones
        final cardPad = EdgeInsets.all(isCompact ? 12 : 24);

        return Scaffold(
          backgroundColor: const Color(0xFFEFF3FF),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isCompact ? 12 : 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _StepIndicators(current: step),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 4,
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: cardPad,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (step == 1) _buildStep1(context, isCompact),
                            if (step == 2) _buildStep2(context, isCompact),
                            if (step == 3) _buildStep3(context, isCompact),

                            const SizedBox(height: 12),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  if (step > 1)
                                    OutlinedButton(
                                      onPressed: () => setState(() => step -= 1),
                                      child: const Text('上一步'),
                                    ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: _handleNext,
                                    child: Text(step == 3 ? '完成設定' : '下一步'),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep1(BuildContext context, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Center(
          child: Column(
            children: [
              Container(
                width: isCompact ? 56 : 64,
                height: isCompact ? 56 : 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
                ),
                alignment: Alignment.center,
                child: Text('W', style: TextStyle(color: Colors.white, fontSize: isCompact ? 24 : 28, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Text('歡迎來到 WEAR', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '讓我們了解你的身材和偏好，為你打造專屬穿搭建議',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 性別
        _Section(
          title: '性別',
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('男性'),
                value: 'male',
                groupValue: profile.gender,
                onChanged: (v) => setState(() => profile.gender = v!),
                dense: true,
              ),
              RadioListTile<String>(
                title: const Text('女性'),
                value: 'female',
                groupValue: profile.gender,
                onChanged: (v) => setState(() => profile.gender = v!),
                dense: true,
              ),
              RadioListTile<String>(
                title: const Text('其他 / 不透露'),
                value: 'other',
                groupValue: profile.gender,
                onChanged: (v) => setState(() => profile.gender = v!),
                dense: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        // 身形資料
        _Section(
          title: '身形資料',
          child: _ResponsiveGrid(
            columnsWhenWide: 2,
            spacing: 12,
            children: [
              _NumberField(label: '身高 (cm)', value: profile.height, onChanged: (v) => setState(() => profile.height = v)),
              _NumberField(label: '體重 (kg)', value: profile.weight, onChanged: (v) => setState(() => profile.weight = v)),
              _NumberField(label: '肩寬 (cm)', value: profile.shoulderWidth, onChanged: (v) => setState(() => profile.shoulderWidth = v)),
              _NumberField(label: '腰圍 (cm)', value: profile.waistline, onChanged: (v) => setState(() => profile.waistline = v)),
            ],
          ),
        ),

        const SizedBox(height: 8),
        // 版型偏好
        _Section(
          title: '版型偏好',
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('修身 Slim Fit'),
                value: 'slim',
                groupValue: profile.fitPreference,
                onChanged: (v) => setState(() => profile.fitPreference = v!),
                dense: true,
              ),
              RadioListTile<String>(
                title: const Text('標準 Regular Fit'),
                value: 'regular',
                groupValue: profile.fitPreference,
                onChanged: (v) => setState(() => profile.fitPreference = v!),
                dense: true,
              ),
              RadioListTile<String>(
                title: const Text('寬鬆 Loose Fit'),
                value: 'loose',
                groupValue: profile.fitPreference,
                onChanged: (v) => setState(() => profile.fitPreference = v!),
                dense: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        // 通勤方式
        _Section(
          title: '通勤方式',
          child: Column(
            children: [
              RadioListTile<String>(title: const Text('步行'), value: 'walk', groupValue: profile.commuteMethod, onChanged: (v) => setState(() => profile.commuteMethod = v!), dense: true),
              RadioListTile<String>(title: const Text('腳踏車'), value: 'bike', groupValue: profile.commuteMethod, onChanged: (v) => setState(() => profile.commuteMethod = v!), dense: true),
              RadioListTile<String>(title: const Text('機車'), value: 'motorcycle', groupValue: profile.commuteMethod, onChanged: (v) => setState(() => profile.commuteMethod = v!), dense: true),
              RadioListTile<String>(title: const Text('汽車'), value: 'car', groupValue: profile.commuteMethod, onChanged: (v) => setState(() => profile.commuteMethod = v!), dense: true),
              RadioListTile<String>(title: const Text('大眾運輸'), value: 'public', groupValue: profile.commuteMethod, onChanged: (v) => setState(() => profile.commuteMethod = v!), dense: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context, bool isCompact) {
    final displayed = getDisplayedStyles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.palette_outlined),
            const SizedBox(width: 8),
            Text('風格與顏色偏好', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _handleOpenStyleDialog,
              icon: const Icon(Icons.add),
              label: const Text('更多風格選項'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Selected style badges (tap to remove)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2),
          ),
          child: displayed.isNotEmpty
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final style in displayed)
                      _RemovableBadge(
                        label: style.label,
                        onRemove: () {
                          if (selectedStyleIds.length <= 1) {
                            _toast('至少需要選擇一個風格');
                            return;
                          }
                          setState(() {
                            selectedStyleIds.remove(style.id);
                            final newWeights = convertSelectedStylesToWeights(selectedStyleIds);
                            profile = _profileWithWeights(newWeights);
                          });
                        },
                        isCustom: style.isCustom,
                      ),
                  ],
                )
              : const _EmptyHint(icon: Icons.auto_awesome_outlined, text: '點擊「更多風格選項」開始選擇您喜歡的風格'),
        ),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFEFF6FF),
          ),
          child: const Text('💡 提示：點擊風格標籤可以取消選擇，系統會自動平均分配權重', style: TextStyle(fontSize: 12)),
        ),

        const SizedBox(height: 20),
        Text('顏色黑名單（不想穿的顏色）', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in availableColors)
              _ColorTile(
                swatch: c,
                blocked: profile.colorBlacklist.contains(c.id),
                onTap: () => setState(() {
                  if (profile.colorBlacklist.contains(c.id)) {
                    profile.colorBlacklist.remove(c.id);
                  } else {
                    profile.colorBlacklist.add(c.id);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3(BuildContext context, bool isCompact) {
    final all = getAllStyleOptions();
    final weights = profile.styleWeights;
    final nonZero = weights.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String fitLabel(String v) {
      switch (v) {
        case 'slim':
          return '修身';
        case 'regular':
          return '標準';
        case 'loose':
          return '寬鬆';
        default:
          return v;
      }
    }

    String commuteLabel(String v) {
      switch (v) {
        case 'motorcycle':
          return '機車';
        case 'public':
          return '大眾運輸';
        case 'car':
          return '汽車';
        case 'bike':
          return '腳踏車';
        case 'walk':
          return '步行';
        default:
          return v;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [const Icon(Icons.check_circle_outline), const SizedBox(width: 8), Text('確認資料', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))]),
        const SizedBox(height: 12),

        // Basic grid
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: _ResponsiveGrid(
            columnsWhenWide: 2,
            spacing: 12,
            children: [
              _KV(label: '身高', value: '${profile.height} cm'),
              _KV(label: '體重', value: '${profile.weight} kg'),
              _KV(label: '版型偏好', value: fitLabel(profile.fitPreference)),
              _KV(label: '通勤方式', value: commuteLabel(profile.commuteMethod)),
            ],
          ),
        ),

        const SizedBox(height: 12),
        // 已選擇的風格
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('已選擇的風格', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
              const SizedBox(height: 8),
              if (selectedStyleIds.isEmpty)
                const Text('尚未選擇風格', style: TextStyle(color: Colors.black45))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in selectedStyleIds)
                      Chip(
                        label: Text(
                          all.firstWhere((s) => s.id == id, orElse: () => StyleOption(id: id, label: id)).label,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('風格權重', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
              const SizedBox(height: 8),
              if (nonZero.isEmpty)
                const Text('未設定風格權重', style: TextStyle(color: Colors.black45))
              else
                ...[
                  for (final e in nonZero)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(all.firstWhere((s) => s.id == e.key, orElse: () => StyleOption(id: e.key, label: e.key)).label),
                        Text('${e.value}%'),
                      ],
                    )
                ],
            ],
          ),
        ),

        if (profile.colorBlacklist.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('不想穿的顏色', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in profile.colorBlacklist)
                      Chip(label: Text(availableColors.firstWhere((c) => c.id == id).label)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _handleNext() {
    if (step < 3) {
      setState(() => step += 1);
    } else {
      widget.onComplete(profile);
    }
  }
}

// ---------------------------- Small UI Pieces ----------------------------

class _StepIndicators extends StatelessWidget {
  final int current; // 1..3
  const _StepIndicators({required this.current});

  Color _color(int s) {
    if (s < current) return Colors.green;
    if (s == current) return const Color(0xFF2563EB);
    return Colors.white;
  }

  Color _textColor(int s) {
    if (s <= current) return Colors.white;
    return Colors.grey.shade500;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      children: [
        for (int s = 1; s <= 3; s++)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color(s),
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
              border: s > current ? Border.all(color: Colors.grey.shade300) : null,
            ),
            alignment: Alignment.center,
            child: s < current
                ? const Icon(Icons.check_circle, color: Colors.white)
                : Text('$s', style: TextStyle(fontWeight: FontWeight.w600, color: _textColor(s))),
          )
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final int columnsWhenWide; // e.g., 2
  final double spacing;
  final List<Widget> children;
  const _ResponsiveGrid({required this.columnsWhenWide, required this.spacing, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isWide = c.maxWidth >= 600; // breakpoint
      if (!isWide) {
        return Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              children[i],
            ]
          ],
        );
      }
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnsWhenWide,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 3.2,
        ),
        itemCount: children.length,
        itemBuilder: (_, i) => children[i],
      );
    });
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _NumberField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final n = int.tryParse(v) ?? value;
            onChanged(n);
          },
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _SelectableBadge extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isCustom;
  final VoidCallback? onDelete;
  const _SelectableBadge({required this.label, required this.selected, required this.onTap, this.isCustom = false, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF2563EB) : Colors.transparent;
    final fg = selected ? Colors.white : Colors.black87;
    final border = selected ? Colors.transparent : Colors.grey.shade400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: fg)),
            if (isCustom) const Padding(padding: EdgeInsets.only(left: 4), child: Text('✨', style: TextStyle(fontSize: 12, color: Colors.white))),
            if (selected) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.check_circle, size: 16, color: Colors.white)),
            if (onDelete != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: InkWell(
                  onTap: onDelete,
                  child: Icon(Icons.close, size: 16, color: selected ? Colors.white70 : Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RemovableBadge extends StatelessWidget {
  final String label;
  final bool isCustom;
  final VoidCallback onRemove;
  const _RemovableBadge({required this.label, required this.onRemove, this.isCustom = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRemove,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            if (isCustom) const Padding(padding: EdgeInsets.only(left: 4), child: Text('✨', style: TextStyle(fontSize: 12, color: Colors.white70))),
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}


class _ColorSwatch {
  final String id;
  final String label;
  final Color color;
  const _ColorSwatch({required this.id, required this.label, required this.color});
}

class _ColorTile extends StatelessWidget {
  final _ColorSwatch swatch;
  final bool blocked;
  final VoidCallback onTap;
  const _ColorTile({required this.swatch, required this.blocked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: swatch.color, borderRadius: BorderRadius.circular(10)),
              ),
              if (blocked)
                Transform.rotate(
                  angle: 0.785398, // 45°
                  child: Container(width: 4, height: 72, color: Colors.red.shade600),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(swatch.label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String label;
  final String value;
  const _KV({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}
