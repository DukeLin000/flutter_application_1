// lib/page/onboarding_page.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

/// 顏色偏好層級（內部狀態使用；儲存時只把 never 丟進 colorBlacklist）
enum ColorPreferenceLevel { like, neutral, avoid, never }

/// 風格選項
class StyleOption {
  final String id;
  final String label;
  final bool isCustom;
  const StyleOption({required this.id, required this.label, this.isCustom = false});
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});
  final void Function(UserProfile) onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // -------------------- Step 控制 --------------------
  int _step = 1;

  // -------------------- 基本資料 --------------------
  String _gender = 'male';
  int _height = 175;
  int _weight = 70;
  int _shoulder = 45;
  int _waist = 80;

  String _fitPreference = 'regular';        // slim | regular | loose
  String _commuteMethod = 'public';         // walk | bike | motorcycle | car | public
  bool _hasMotorcycle = false;              // 保留欄位對齊你的模型

  // -------------------- 風格 --------------------
  final List<StyleOption> _defaultStyles = const [
    StyleOption(id: 'street', label: '街頭'),
    StyleOption(id: 'outdoor', label: '戶外'),
    StyleOption(id: 'office', label: '上班'),
    StyleOption(id: 'sporty', label: '運動'),
    StyleOption(id: 'minimal', label: '極簡'),
    StyleOption(id: 'vintage', label: '復古'),
  ];
  final List<String> _defaultSelected = const ['street', 'outdoor', 'office'];
  final List<StyleOption> _customStyles = [];
  late List<String> _selectedStyleIds = [..._defaultSelected];

  // styleWeights（0~100，總和=100）
  Map<String, int> _styleWeights = {};

  // Dialog 用暫存
  bool _isStyleDialogOpen = false;
  final TextEditingController _newStyleCtrl = TextEditingController();
  late List<String> _tempSelectedStyleIds = [..._selectedStyleIds];

  // -------------------- 顏色偏好 --------------------
  bool _showNever = false; // 「絕不建議」開關
  final Map<String, ColorPreferenceLevel> _colorPrefs = {};

  // 色票（id / label / color）
  final List<(String id, String label, Color color)> _basicColors = const [
    ('black', '黑色', Colors.black),
    ('white', '白色', Colors.white),
  ];
  final List<(String id, String label, Color color)> _moreColors = const [
    ('pink',   '粉紅',  Color(0xFFF472B6)),
    ('purple', '紫色',  Color(0xFFA78BFA)),
    ('yellow', '黃色',  Color(0xFFFACC15)),
    ('orange', '橘色',  Color(0xFFF59E0B)),
    ('green',  '綠色',  Color(0xFF34D399)),
    ('red',    '紅色',  Color(0xFFEF4444)),
    ('gray',   '灰色',  Color(0xFF9CA3AF)),
    ('brown',  '棕色',  Color(0xFF92400E)),
    ('navy',   '深藍',  Color(0xFF1E3A8A)),
    ('beige',  '米色',  Color(0xFFF5F5DC)),
  ];
  bool _expandMoreColors = false;

  @override
  void initState() {
    super.initState();
    _styleWeights = _equalizeWeights(_selectedStyleIds);
  }

  // 依容器寬度給最大內容寬
  double _maxW(double w) {
    if (w >= 1600) return 1100;
    if (w >= 1200) return 1000;
    if (w >= 900) return 860;
    if (w >= 600) return 560;
    return w - 24;
  }

  // 權重平均（總和 100）
  Map<String, int> _equalizeWeights(List<String> ids) {
    final map = <String, int>{};
    if (ids.isEmpty) return map;
    final base = (100 ~/ ids.length);
    var remain = 100 - base * ids.length;
    for (var i = 0; i < ids.length; i++) {
      map[ids[i]] = base + (i < remain ? 1 : 0);
    }
    return map;
  }

  List<StyleOption> get _allStyles => [..._defaultStyles, ..._customStyles];

  void _toggleTempStyle(String id) {
    setState(() {
      if (_tempSelectedStyleIds.contains(id)) {
        _tempSelectedStyleIds.remove(id);
      } else {
        _tempSelectedStyleIds.add(id);
      }
    });
  }

  void _confirmStyleSelection() {
    setState(() {
      _selectedStyleIds = _tempSelectedStyleIds.isEmpty ? [..._defaultSelected] : [..._tempSelectedStyleIds];
      _styleWeights = _equalizeWeights(_selectedStyleIds);
      _isStyleDialogOpen = false;
    });
  }

  void _addCustomStyle() {
    final name = _newStyleCtrl.text.trim();
    if (name.isEmpty) return;
    // 簡單驗證：不可重複
    final exists = _allStyles.any((s) => s.label == name);
    if (exists) return;

    final id = 'custom_${name.hashCode.abs()}';
    setState(() {
      _customStyles.add(StyleOption(id: id, label: name, isCustom: true));
      _tempSelectedStyleIds.add(id);
      _newStyleCtrl.clear();
    });
  }

  // 偏好 setter / getter
  void _setColorPref(String id, ColorPreferenceLevel level) {
    setState(() => _colorPrefs[id] = level);
  }

  ColorPreferenceLevel _getColorPref(String id) {
    return _colorPrefs[id] ?? ColorPreferenceLevel.neutral;
  }

  // 完成 → 輸出 UserProfile
  void _finish() {
    // 把 never 顏色轉成 colorBlacklist（其餘等級不落地到模型，之後你要擴充可再加欄位）
    final blacklist = _colorPrefs.entries
        .where((e) => e.value == ColorPreferenceLevel.never)
        .map((e) => e.key)
        .toList();

    final profile = UserProfile(
      height: _height,
      weight: _weight,
      shoulderWidth: _shoulder,
      waistline: _waist,
      fitPreference: _fitPreference,
      colorBlacklist: blacklist,
      hasMotorcycle: _hasMotorcycle,
      commuteMethod: _commuteMethod,
      styleWeights: _styleWeights,
      gender: _gender,
    );

    widget.onComplete(profile);
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _maxW(w)),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  _buildStepper(context),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_step == 1) _stepBasic(context),
                          if (_step == 2) _stepStyleAndColors(context),
                          if (_step == 3) _stepReview(context),
                          const Divider(height: 28),
                          _buildFooterButtons(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 進度顯示
  Widget _buildStepper(BuildContext context) {
    Widget dot(int s) {
      final isDone = s < _step;
      final isNow = s == _step;
      final bg = isDone
          ? Colors.green
          : isNow
              ? Theme.of(context).colorScheme.primary
              : Colors.white;
      final fg = (isDone || isNow) ? Colors.white : Colors.grey;

      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: isNow
              ? [BoxShadow(color: bg.withOpacity(.25), blurRadius: 10)]
              : null,
        ),
        child: Center(
          child: isDone
              ? const Icon(Icons.check_circle, size: 22, color: Colors.white)
              : Text('$s', style: TextStyle(fontSize: 18, color: fg)),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(1), const SizedBox(width: 12),
        dot(2), const SizedBox(width: 12),
        dot(3),
      ],
    );
  }

  // -------------------- Step 1：基本資料 --------------------
  Widget _stepBasic(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              // ← 統一為黑漸層 Logo 方塊（與 Login 相同樣式）
              const BlackLogoBox(), // 預設 80x80，可改 size 參數
              const SizedBox(height: 10),
              Text('歡迎來到神穿 StylistOS', style: tt.titleLarge),
              const SizedBox(height: 6),
              Text(
                '讓我們了解你的身材和偏好，為你打造專屬穿搭建議',
                style: tt.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 性別
        Text('性別', style: tt.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 18,
          children: [
            _radio('男性', 'male', group: _gender, onChanged: (v) => setState(() => _gender = v)),
            _radio('女性', 'female', group: _gender, onChanged: (v) => setState(() => _gender = v)),
            _radio('其他 / 不透露', 'other', group: _gender, onChanged: (v) => setState(() => _gender = v)),
          ],
        ),
        const SizedBox(height: 16),

        // 身形
        LayoutBuilder(
          builder: (_, c) {
            final twoCols = c.maxWidth >= 520;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: twoCols ? 2 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: twoCols ? 5 : 6,
              ),
              children: [
                _numberField('身高 (cm)', _height, (v) => setState(() => _height = v)),
                _numberField('體重 (kg)', _weight, (v) => setState(() => _weight = v)),
                _numberField('肩寬 (cm)', _shoulder, (v) => setState(() => _shoulder = v)),
                _numberField('腰圍 (cm)', _waist, (v) => setState(() => _waist = v)),
              ],
            );
          },
        ),
        const SizedBox(height: 12),

        // 版型
        Text('版型偏好', style: tt.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 18,
          children: [
            _radio('修身 Slim Fit', 'slim', group: _fitPreference, onChanged: (v) => setState(() => _fitPreference = v)),
            _radio('標準 Regular Fit', 'regular', group: _fitPreference, onChanged: (v) => setState(() => _fitPreference = v)),
            _radio('寬鬆 Loose Fit', 'loose', group: _fitPreference, onChanged: (v) => setState(() => _fitPreference = v)),
          ],
        ),
        const SizedBox(height: 16),

        // 通勤
        Text('通勤方式', style: tt.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 18,
          children: [
            _radio('步行', 'walk', group: _commuteMethod, onChanged: (v) => setState(() => _commuteMethod = v)),
            _radio('腳踏車', 'bike', group: _commuteMethod, onChanged: (v) => setState(() => _commuteMethod = v)),
            _radio('機車', 'motorcycle', group: _commuteMethod, onChanged: (v) { setState(() { _commuteMethod = v; _hasMotorcycle = true; }); }),
            _radio('汽車', 'car', group: _commuteMethod, onChanged: (v) => setState(() => _commuteMethod = v)),
            _radio('大眾運輸', 'public', group: _commuteMethod, onChanged: (v) => setState(() => _commuteMethod = v)),
          ],
        ),
      ],
    );
  }

  // -------------------- Step 2：風格 + 顏色 --------------------
  Widget _stepStyleAndColors(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 風格
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('選擇你喜歡的風格', style: tt.titleMedium),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _tempSelectedStyleIds = [..._selectedStyleIds];
                  _isStyleDialogOpen = true;
                });
                showDialog(
                  context: context,
                  builder: (_) => _styleDialog(context),
                ).then((_) => setState(() => _isStyleDialogOpen = false));
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('更多風格選項'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 1.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedStyleIds.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.grey, size: 28),
                    const SizedBox(height: 6),
                    Text('點擊「更多風格選項」開始選擇', style: tt.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedStyleIds.map((id) {
                    final style = _allStyles.firstWhere((s) => s.id == id);
                    return GestureDetector(
                      onTap: () {
                        if (_selectedStyleIds.length <= 1) return;
                        setState(() {
                          _selectedStyleIds.remove(id);
                          _styleWeights = _equalizeWeights(_selectedStyleIds);
                        });
                      },
                      child: Chip(
                        label: Text(style.label, style: const TextStyle(color: Colors.white)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        deleteIcon: const Icon(Icons.close, color: Colors.white70, size: 18),
                        onDeleted: null,
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // 顏色偏好（提示 + 基本色）
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('顏色偏好設定', style: tt.titleMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _legendDot(color: Colors.pink, label: '喜歡：優先推薦'),
                  _legendDot(color: Colors.grey, label: '普通：正常推薦'),
                  _legendDot(color: Colors.orange, label: '少穿：降低推薦'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(value: _showNever, onChanged: (v) => setState(() => _showNever = v)),
                      const SizedBox(width: 6),
                      const Text('顯示「絕不建議」'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 基本色（固定高度避免溢位）
        LayoutBuilder(
          builder: (_, c) {
            final twoCols = c.maxWidth >= 520;
            final extent = twoCols ? 164.0 : 156.0;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: twoCols ? 2 : 1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: extent, // 固定主軸高度
              ),
              children: _basicColors.map((e) => _colorTile(e)).toList(),
            );
          },
        ),
        const SizedBox(height: 8),

        // 更多顏色（可展開）— 同樣用固定高度避免溢位
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: _expandMoreColors,
          onExpansionChanged: (v) => setState(() => _expandMoreColors = v),
          title: Row(
            children: const [
              Icon(Icons.palette_outlined, size: 18),
              SizedBox(width: 6),
              Text('更多顏色偏好設定'),
            ],
          ),
          children: [
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (_, c) {
                final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 600 ? 2 : 1);
                final extent = cols >= 2 ? 164.0 : 156.0;
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: extent,
                  ),
                  children: _moreColors.map((e) => _colorTile(e)).toList(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // 顏色卡片
  Widget _colorTile((String id, String label, Color color) e) {
    final pref = _getColorPref(e.$1);

    Widget prefBtn(
      ColorPreferenceLevel level,
      IconData icon,
      Color active, {
      String? tooltip,
    }) {
      final selected = pref == level;
      return Expanded(
        child: Tooltip(
          message: tooltip ?? level.name,
          child: InkWell(
            onTap: () => _setColorPref(e.$1, level),
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 6), // 較小避免撐高
              decoration: BoxDecoration(
                color: selected ? active : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: e.$3,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: e.$3.computeLuminance() > .8
                    ? Colors.grey.shade300
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(e.$2, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          // 固定底部控制列高度，避免被內容撐高
          SizedBox(
            height: 36,
            child: Row(
              children: [
                prefBtn(ColorPreferenceLevel.like, Icons.favorite, Colors.pink, tooltip: '喜歡'),
                const SizedBox(width: 6),
                prefBtn(ColorPreferenceLevel.neutral, Icons.remove, Colors.grey, tooltip: '普通'),
                const SizedBox(width: 6),
                prefBtn(ColorPreferenceLevel.avoid, Icons.block, Colors.orange, tooltip: '少穿'),
                if (_showNever) ...[
                  const SizedBox(width: 6),
                  prefBtn(ColorPreferenceLevel.never, Icons.shield, Colors.red, tooltip: '絕不建議'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Step 3：確認 --------------------
  Widget _stepReview(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final styles = _selectedStyleIds
        .map((id) => (_allStyles.firstWhere((s) => s.id == id).label, _styleWeights[id] ?? 0))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    List<(String id, String label)> _byLevel(ColorPreferenceLevel level) {
      final all = [..._basicColors, ..._moreColors];
      final ids = _colorPrefs.entries.where((e) => e.value == level).map((e) => e.key).toSet();
      return all.where((c) => ids.contains(c.$1)).map((c) => (c.$1, c.$2)).toList();
    }

    Widget tag(String text, Color bg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 基本欄位
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: LayoutBuilder(builder: (_, c) {
            final twoCols = c.maxWidth >= 520;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: twoCols ? 2 : 1,
                mainAxisSpacing: 8,
                crossAxisSpacing: 12,
                childAspectRatio: 6,
              ),
              children: [
                _kv('身高', '$_height cm'),
                _kv('體重', '$_weight kg'),
                _kv('版型偏好', _fitPreference == 'slim' ? '修身' : _fitPreference == 'regular' ? '標準' : '寬鬆'),
                _kv('通勤方式', {
                  'walk': '步行',
                  'bike': '腳踏車',
                  'motorcycle': '機車',
                  'car': '汽車',
                  'public': '大眾運輸'
                }[_commuteMethod] ?? _commuteMethod),
              ],
            );
          }),
        ),
        const SizedBox(height: 12),

        // 風格權重
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('風格權重', style: tt.titleMedium),
              const SizedBox(height: 8),
              if (styles.isEmpty)
                Text('未設定風格權重', style: tt.bodySmall?.copyWith(color: Colors.grey))
              else
                ...styles.map((e) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text(e.$1), Text('${e.$2}%')],
                    )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 顏色偏好摘要
        if (_colorPrefs.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('顏色偏好', style: tt.titleMedium),
                const SizedBox(height: 8),
                if (_byLevel(ColorPreferenceLevel.like).isNotEmpty) ...[
                  Row(children: const [Icon(Icons.favorite, color: Colors.pink, size: 16), SizedBox(width: 6), Text('喜歡')]),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _byLevel(ColorPreferenceLevel.like).map((e) => tag(e.$2, Colors.pink)).toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_byLevel(ColorPreferenceLevel.avoid).isNotEmpty) ...[
                  Row(children: const [Icon(Icons.block, color: Colors.orange, size: 16), SizedBox(width: 6), Text('少穿')]),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _byLevel(ColorPreferenceLevel.avoid).map((e) => tag(e.$2, Colors.orange)).toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_showNever && _byLevel(ColorPreferenceLevel.never).isNotEmpty) ...[
                  Row(children: const [Icon(Icons.shield, color: Colors.red, size: 16), SizedBox(width: 6), Text('絕不建議')]),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _byLevel(ColorPreferenceLevel.never).map((e) => tag(e.$2, Colors.red)).toList(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  // -------------------- Footer Buttons --------------------
  Widget _buildFooterButtons() {
    return Row(
      children: [
        if (_step > 1)
          OutlinedButton(
            onPressed: () => setState(() => _step -= 1),
            child: const Text('上一步'),
          ),
        const Spacer(),
        FilledButton(
          onPressed: () {
            if (_step < 3) {
              setState(() => _step += 1);
            } else {
              _finish();
            }
          },
          child: Text(_step == 3 ? '完成設定' : '下一步'),
        ),
      ],
    );
  }

  // -------------------- Dialog: 風格選擇 --------------------
  Widget _styleDialog(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: const [Icon(Icons.style, size: 20), SizedBox(width: 8), Text('選擇您喜歡的風格')]),
              const SizedBox(height: 12),
              // 新增自訂風格
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newStyleCtrl,
                      decoration: const InputDecoration(
                        hintText: '輸入風格名稱（如：嘻哈、龐克）',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addCustomStyle(),
                      maxLength: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _addCustomStyle,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新增'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 標籤選擇
              SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allStyles.map((s) {
                    final selected = _tempSelectedStyleIds.contains(s.id);
                    return ChoiceChip(
                      selected: selected,
                      label: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(s.label),
                        if (s.isCustom) const SizedBox(width: 4),
                        if (s.isCustom) const Text('✨', style: TextStyle(fontSize: 12)),
                      ]),
                      onSelected: (_) => _toggleTempStyle(s.id),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('已選擇 ${_tempSelectedStyleIds.length} 個風格', style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      _confirmStyleSelection();
                      Navigator.pop(context);
                    },
                    child: const Text('確認選擇'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- 小元件 --------------------
  Widget _radio(String label, String value, {required String group, required ValueChanged<String> onChanged}) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(value: value, groupValue: group, onChanged: (v) => v != null ? onChanged(v) : null),
          Text(label),
        ],
      ),
    );
  }

  Widget _numberField(String label, int value, ValueChanged<int> onChanged) {
    final ctrl = TextEditingController(text: value.toString());
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      onChanged: (s) {
        final v = int.tryParse(s);
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))],
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// 共用：黑漸層 Logo 方塊（灰→黑漸層、22 圓角、陰影、置中白色「S」）
class BlackLogoBox extends StatelessWidget {
  final double size;
  final double radius;
  final String letter;
  const BlackLogoBox({
    super.key,
    this.size = 80,
    this.radius = 22,
    this.letter = 'S',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9CA3AF), Color(0xFF111827)], // gray-400 → gray-900
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: .5,
        ),
      ),
    );
  }
}
