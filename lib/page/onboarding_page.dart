import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/s_flow_design.dart'; // ✅ 1. 引入全域設計系統

// ==========================================
// Onboarding Page Logic
// ==========================================

enum ColorPreferenceLevel { like, neutral, avoid, never }

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
  bool _isPurple = true; // Theme state
  int _step = 1;

  // Basic Data
  String _gender = 'male';
  int _height = 175;
  int _weight = 70;
  int _shoulder = 45;
  int _waist = 80;
  String _fitPreference = 'regular';
  String _commuteMethod = 'public';
  bool _hasMotorcycle = false;

  // Styles
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
  Map<String, int> _styleWeights = {};

  // Dialog temp
  final TextEditingController _newStyleCtrl = TextEditingController();
  late List<String> _tempSelectedStyleIds = [..._selectedStyleIds];

  // Colors
  bool _showNever = false;
  final Map<String, ColorPreferenceLevel> _colorPrefs = {};

  final List<(String id, String label, Color color)> _basicColors = const [
    ('black', '黑色', Colors.black),
    ('white', '白色', Colors.white),
  ];
  final List<(String id, String label, Color color)> _moreColors = const [
    ('pink', '粉紅', Color(0xFFF472B6)),
    ('purple', '紫色', Color(0xFFA78BFA)),
    ('yellow', '黃色', Color(0xFFFACC15)),
    ('orange', '橘色', Color(0xFFF59E0B)),
    ('green', '綠色', Color(0xFF34D399)),
    ('red', '紅色', Color(0xFFEF4444)),
    ('gray', '灰色', Color(0xFF9CA3AF)),
    ('brown', '棕色', Color(0xFF92400E)),
    ('navy', '深藍', Color(0xFF1E3A8A)),
    ('beige', '米色', Color(0xFFF5F5DC)),
  ];
  bool _expandMoreColors = false;

  // ✅ 2. 使用全域 SFlowThemes
  SFlowColors get _currentTheme => _isPurple ? SFlowThemes.purple : SFlowThemes.gold;

  @override
  void initState() {
    super.initState();
    _styleWeights = _equalizeWeights(_selectedStyleIds);
  }

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

  void _finish() {
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
    // 注意：目前的 UserProfile 模型不包含 themePreference。
    // 如果您希望將這裡選擇的主題(金/紫)應用到 App，您可能需要更新 onComplete 回調或 UserProfile 模型。
    widget.onComplete(profile);
  }

  // ==========================================
  // UI Construction
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final colors = _currentTheme;
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        // ✅ 3. 使用 SFlowBackground 邏輯或漸層
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.bgGradient,
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundGlow(colors),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 800 : w - 32),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        // Header with Theme Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStepper(colors),
                            IconButton(
                              onPressed: () => setState(() => _isPurple = !_isPurple),
                              icon: Icon(
                                _isPurple ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Main Glass Card
                        // ✅ 4. 使用 S-FLOW 的 GlassContainer
                        GlassContainer(
                          colors: colors,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Column(
                              key: ValueKey(_step),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_step == 1) _stepBasic(colors),
                                if (_step == 2) _stepStyleAndColors(colors),
                                if (_step == 3) _stepReview(colors),
                                const SizedBox(height: 32),
                                Divider(color: colors.glassBorder),
                                const SizedBox(height: 16),
                                _buildFooterButtons(colors),
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
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow(SFlowColors colors) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.secondary.withOpacity(0.15),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withOpacity(0.15),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepper(SFlowColors colors) {
    Widget dot(int s) {
      final isDone = s < _step;
      final isNow = s == _step;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isNow ? 32 : 12,
        height: 12,
        decoration: BoxDecoration(
          color: isDone || isNow ? colors.primary : colors.text.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isNow ? [BoxShadow(color: colors.primary.withOpacity(0.4), blurRadius: 8)] : null,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(1), const SizedBox(width: 8),
        dot(2), const SizedBox(width: 8),
        dot(3),
      ],
    );
  }

  // -------------------- Step 1: Basic Info --------------------
  Widget _stepBasic(SFlowColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WELCOME TO S-FLOW', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('建立您的個人檔案', style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('讓我們了解您的身形數據，AI 將為您提供最精準的穿搭建議。', style: TextStyle(color: colors.textDim)),
        
        const SizedBox(height: 32),
        _sectionHeader('GENDER', colors),
        Wrap(
          spacing: 12,
          children: [
            _selectableBtn('男性', _gender == 'male', () => setState(() => _gender = 'male'), colors),
            _selectableBtn('女性', _gender == 'female', () => setState(() => _gender = 'female'), colors),
            _selectableBtn('其他', _gender == 'other', () => setState(() => _gender = 'other'), colors),
          ],
        ),

        const SizedBox(height: 24),
        _sectionHeader('MEASUREMENTS', colors),
        LayoutBuilder(builder: (_, c) {
          final wide = c.maxWidth > 500;
          return GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: wide ? 2 : 1,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: wide ? 4 : 5,
            ),
            children: [
              _glassInput('身高 (cm)', _height, (v) => setState(() => _height = v), colors),
              _glassInput('體重 (kg)', _weight, (v) => setState(() => _weight = v), colors),
              _glassInput('肩寬 (cm)', _shoulder, (v) => setState(() => _shoulder = v), colors),
              _glassInput('腰圍 (cm)', _waist, (v) => setState(() => _waist = v), colors),
            ],
          );
        }),

        const SizedBox(height: 24),
        _sectionHeader('PREFERENCE', colors),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            _selectableBtn('修身 Slim', _fitPreference == 'slim', () => setState(() => _fitPreference = 'slim'), colors),
            _selectableBtn('標準 Regular', _fitPreference == 'regular', () => setState(() => _fitPreference = 'regular'), colors),
            _selectableBtn('寬鬆 Loose', _fitPreference == 'loose', () => setState(() => _fitPreference = 'loose'), colors),
          ],
        ),

        const SizedBox(height: 24),
        _sectionHeader('COMMUTE', colors),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            _selectableBtn('大眾運輸', _commuteMethod == 'public', () => setState(() => _commuteMethod = 'public'), colors),
            _selectableBtn('機車', _commuteMethod == 'motorcycle', () { setState(() { _commuteMethod = 'motorcycle'; _hasMotorcycle = true; }); }, colors),
            _selectableBtn('汽車', _commuteMethod == 'car', () => setState(() => _commuteMethod = 'car'), colors),
            _selectableBtn('步行', _commuteMethod == 'walk', () => setState(() => _commuteMethod = 'walk'), colors),
          ],
        ),
      ],
    );
  }

  // -------------------- Step 2: Style & Colors --------------------
  Widget _stepStyleAndColors(SFlowColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STYLE & COLORS', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('風格偏好設定', style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.bold)),
        
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader('FAVORITE STYLES', colors),
            TextButton.icon(
              onPressed: () => _openStyleDialog(context, colors),
              icon: Icon(Icons.add, color: colors.secondary, size: 16),
              label: Text('更多', style: TextStyle(color: colors.secondary)),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedStyleIds.map((id) {
            final style = _allStyles.firstWhere((s) => s.id == id, orElse: () => StyleOption(id: id, label: id));
            return Chip(
              backgroundColor: colors.primary.withOpacity(0.2),
              side: BorderSide(color: colors.primary.withOpacity(0.5)),
              label: Text(style.label, style: TextStyle(color: colors.text)),
              deleteIcon: Icon(Icons.close, size: 14, color: colors.textDim),
              onDeleted: () {
                if (_selectedStyleIds.length > 1) {
                  setState(() {
                    _selectedStyleIds.remove(id);
                    _styleWeights = _equalizeWeights(_selectedStyleIds);
                  });
                }
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 32),
        _sectionHeader('COLOR PREFERENCES', colors),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.glassBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.glassBorder),
          ),
          child: Column(
            children: [
              // Legend
              Wrap(
                spacing: 16,
                children: [
                  _legendItem(Icons.favorite, Colors.pink, '喜歡', colors),
                  _legendItem(Icons.remove, Colors.grey, '普通', colors),
                  _legendItem(Icons.block, Colors.orange, '少穿', colors),
                  if (_showNever) _legendItem(Icons.shield, Colors.red, '絕不', colors),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: colors.primary,
                title: Text('顯示「絕不建議」選項', style: TextStyle(color: colors.textDim, fontSize: 14)),
                value: _showNever,
                onChanged: (v) => setState(() => _showNever = v),
              ),
              Divider(color: colors.glassBorder),
              const SizedBox(height: 8),
              
              // Color Grid
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ..._basicColors.map((e) => _colorSelector(e, colors)),
                  if (_expandMoreColors) ..._moreColors.map((e) => _colorSelector(e, colors)),
                ],
              ),
              if (!_expandMoreColors)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () => setState(() => _expandMoreColors = true),
                    child: Text('顯示更多顏色', style: TextStyle(color: colors.secondary)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------- Step 3: Review --------------------
  Widget _stepReview(SFlowColors colors) {
    final styles = _selectedStyleIds
        .map((id) => (_allStyles.firstWhere((s) => s.id == id, orElse: () => StyleOption(id: id, label: id)).label, _styleWeights[id] ?? 0))
        .toList()..sort((a, b) => b.$2.compareTo(a.$2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REVIEW', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('確認您的設定', style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.bold)),
        
        const SizedBox(height: 32),
        _sectionHeader('SUMMARY', colors),
        
        // Basic Info Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.glassBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.glassBorder),
          ),
          child: Column(
            children: [
              _summaryRow('身高 / 體重', '$_height cm / $_weight kg', colors),
              Divider(color: colors.glassBorder, height: 24),
              _summaryRow('版型 / 通勤', '${_fitPreference.toUpperCase()} / ${_commuteMethod.toUpperCase()}', colors),
            ],
          ),
        ),

        const SizedBox(height: 16),
        // Style Weights
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.glassBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('風格權重分佈', style: TextStyle(color: colors.textDim, fontSize: 12)),
              const SizedBox(height: 12),
              ...styles.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(e.$1, style: TextStyle(color: colors.text))),
                    Expanded(
                      flex: 7,
                      child: Stack(
                        children: [
                          Container(height: 6, decoration: BoxDecoration(color: colors.glassBorder, borderRadius: BorderRadius.circular(3))),
                          Container(
                            height: 6, 
                            width: (e.$2 * 2.0).clamp(0, 200),
                            decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(3)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${e.$2}%', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Helper Widgets
  // ==========================================

  Widget _sectionHeader(String title, SFlowColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(color: colors.secondary.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
    );
  }

  Widget _selectableBtn(String label, bool selected, VoidCallback onTap, SFlowColors colors) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withOpacity(0.2) : colors.glassBg,
          border: Border.all(color: selected ? colors.primary : colors.glassBorder),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? [BoxShadow(color: colors.primary.withOpacity(0.4), blurRadius: 8)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.primary : colors.textDim,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _glassInput(String label, int value, ValueChanged<int> onChanged, SFlowColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textDim, fontSize: 12)),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.glassBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.glassBorder),
            ),
            alignment: Alignment.center,
            child: TextFormField(
              initialValue: value.toString(),
              keyboardType: TextInputType.number,
              // ✅ 修正：使用 theme text color，避免在淺色背景下看不見
              style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(border: InputBorder.none),
              onChanged: (v) => onChanged(int.tryParse(v) ?? value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorSelector((String id, String label, Color color) item, SFlowColors colors) {
    final pref = _colorPrefs[item.$1] ?? ColorPreferenceLevel.neutral;
    
    void cycle() {
      final next = switch (pref) {
        ColorPreferenceLevel.neutral => ColorPreferenceLevel.like,
        ColorPreferenceLevel.like => ColorPreferenceLevel.avoid,
        ColorPreferenceLevel.avoid => _showNever ? ColorPreferenceLevel.never : ColorPreferenceLevel.neutral,
        ColorPreferenceLevel.never => ColorPreferenceLevel.neutral,
      };
      setState(() => _colorPrefs[item.$1] = next);
    }

    IconData? icon;
    Color iconColor = colors.text;
    if (pref == ColorPreferenceLevel.like) { icon = Icons.favorite; iconColor = Colors.pink; }
    if (pref == ColorPreferenceLevel.avoid) { icon = Icons.block; iconColor = Colors.orange; }
    if (pref == ColorPreferenceLevel.never) { icon = Icons.shield; iconColor = Colors.red; }

    return GestureDetector(
      onTap: cycle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black26, // Color chip background usually stays dark
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pref == ColorPreferenceLevel.neutral ? colors.glassBorder : iconColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: item.$3,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(item.$2, style: TextStyle(color: colors.text.withOpacity(0.7), fontSize: 12))),
            if (icon != null) Icon(icon, size: 16, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(IconData icon, Color color, String label, SFlowColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _summaryRow(String label, String value, SFlowColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textDim)),
        Text(value, style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFooterButtons(SFlowColors colors) {
    return Row(
      children: [
        if (_step > 1)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: Text('BACK', style: TextStyle(color: colors.text.withOpacity(0.5))),
          ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            if (_step < 3) {
              setState(() => _step++);
            } else {
              _finish();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: colors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Text(
              _step == 3 ? 'COMPLETE' : 'NEXT',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }

  void _openStyleDialog(BuildContext context, SFlowColors colors) {
    _tempSelectedStyleIds = [..._selectedStyleIds];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: GlassContainer(
              colors: colors,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('選擇喜歡的風格', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newStyleCtrl,
                      style: TextStyle(color: colors.text),
                      decoration: InputDecoration(
                        hintText: '新增自訂風格...',
                        hintStyle: TextStyle(color: colors.textDim),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.glassBorder)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.primary)),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.add, color: colors.text),
                          onPressed: () {
                            if (_newStyleCtrl.text.isNotEmpty) {
                              setState(() {
                                final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
                                _customStyles.add(StyleOption(id: newId, label: _newStyleCtrl.text, isCustom: true));
                                _tempSelectedStyleIds.add(newId);
                                _newStyleCtrl.clear();
                              });
                              setDialogState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allStyles.map((s) {
                            final selected = _tempSelectedStyleIds.contains(s.id);
                            return FilterChip(
                              label: Text(s.label),
                              selected: selected,
                              onSelected: (_) {
                                setDialogState(() {
                                  selected ? _tempSelectedStyleIds.remove(s.id) : _tempSelectedStyleIds.add(s.id);
                                });
                              },
                              backgroundColor: colors.glassBg,
                              selectedColor: colors.primary.withOpacity(0.3),
                              checkmarkColor: colors.primary,
                              labelStyle: TextStyle(color: selected ? colors.primary : colors.textDim),
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('取消', style: TextStyle(color: colors.textDim)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.black),
                          onPressed: () {
                            setState(() {
                              _selectedStyleIds = [..._tempSelectedStyleIds];
                              _styleWeights = _equalizeWeights(_selectedStyleIds);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('確認'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}