// lib/page/profilepage/settings_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class SettingsPage extends StatefulWidget {
  final UserProfile userProfile;
  final void Function(UserProfile updated) onUpdateProfile;
  final VoidCallback onLogout;
  final VoidCallback? onBack;

  const SettingsPage({
    super.key,
    required this.userProfile,
    required this.onUpdateProfile,
    required this.onLogout,
    this.onBack,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _StyleOption {
  final String id;
  final String label;
  final bool isCustom;
  const _StyleOption(this.id, this.label, {this.isCustom = false});
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  late UserProfile _profile;
  bool _hasChanges = false;

  bool _dailyOutfit = true;
  bool _weatherAlert = true;
  bool _rainReminder = true;
  bool _communityLikes = true;
  bool _communityComments = false;

  final List<_StyleOption> _defaultStyles = const [
    _StyleOption('street', '街頭'),
    _StyleOption('outdoor', '戶外'),
    _StyleOption('office', '上班'),
    _StyleOption('smart_casual', '休閒紳士'),
    _StyleOption('minimal', '極簡'),
    _StyleOption('techwear', '機能'),
    _StyleOption('workwear', '工裝'),
    _StyleOption('preppy', '學院'),
    _StyleOption('sport', '運動'),
    _StyleOption('vintage', '復古'),
  ];
  final List<_StyleOption> _customStyles = [];
  late List<String> _selectedStyleIds;

  bool _isStyleDialogOpen = false;
  final TextEditingController _newStyleCtrl = TextEditingController();
  List<String> _tempSelected = [];

  final TextEditingController _emailCtrl = TextEditingController(text: 'demo@wear.com');
  final TextEditingController _pwdCurrentCtrl = TextEditingController();
  final TextEditingController _pwdNewCtrl = TextEditingController();
  final TextEditingController _pwdConfirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = widget.userProfile;
    _selectedStyleIds = _getSelectedStylesFromWeights(_profile.styleWeights);
    if (_selectedStyleIds.isEmpty) {
      _selectedStyleIds = ['street', 'outdoor', 'office'];
      _profile = _profile.copyWith(styleWeights: _convertSelectedToWeights(_selectedStyleIds));
    }
  }

  @override
  void dispose() {
    _newStyleCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCurrentCtrl.dispose();
    _pwdNewCtrl.dispose();
    _pwdConfirmCtrl.dispose();
    super.dispose();
  }

  void _markChanged([UserProfile? p]) {
    if (p != null) _profile = p;
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  int _parseInt(String v, int fallback) {
    final x = int.tryParse(v);
    return x == null || x <= 0 ? fallback : x;
  }

  String _slugify(String name) {
    final lowered = name.trim().toLowerCase();
    final slug = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
    return slug.replaceAll(RegExp(r'^_|_$'), '');
  }

  List<String> _getSelectedStylesFromWeights(Map<String, int> weights) {
    return weights.entries.where((e) => (e.value) > 0).map((e) => e.key).toList();
  }

  Map<String, int> _convertSelectedToWeights(List<String> ids) {
    if (ids.isEmpty) return {};
    final base = 100 ~/ ids.length;
    int rem = 100 % ids.length;
    final map = <String, int>{};
    for (final id in ids) {
      map[id] = base + (rem > 0 ? 1 : 0);
      if (rem > 0) rem--;
    }
    return map;
  }

  Map<String, int> _clearAllWeights() => {};
  List<_StyleOption> _allStyles() => [..._defaultStyles, ..._customStyles];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('個人設定'),
        leading: widget.onBack == null
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final maxW = w >= 1200 ? 1000.0 : (w >= 900 ? 900.0 : (w * 0.96));
          final tabs = const [
            Tab(text: '個人資料', icon: Icon(Icons.person_outline)),
            Tab(text: '風格偏好', icon: Icon(Icons.palette_outlined)),
            Tab(text: '通知', icon: Icon(Icons.notifications_outlined)),
            Tab(text: '帳號', icon: Icon(Icons.lock_outline)),
          ];

          return DefaultTabController(
            length: tabs.length,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(w >= 1200 ? 24 : 16, 12, w >= 1200 ? 24 : 16, 24),
                  child: Column(
                    children: [
                      if (_hasChanges) _unsavedBar(context),
                      Material(
                        color: Colors.transparent,
                        child: TabBar(isScrollable: w < 520, labelPadding: const EdgeInsets.symmetric(horizontal: 12), tabs: tabs),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildProfileTab(context, w),
                            _buildStyleTab(context, w),
                            _buildNotificationsTab(context),
                            _buildAccountTab(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ 修正這段：去掉多餘的括號
  Widget _unsavedBar(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.save_outlined, color: Color(0xFF2563EB)),
        title: const Text('您有未儲存的變更', style: TextStyle(color: Color(0xFF1E3A8A))),
        trailing: FilledButton(
          onPressed: () {
            widget.onUpdateProfile(_profile);
            setState(() => _hasChanges = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('個人設定已儲存')));
          },
          child: const Text('儲存變更'),
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, double w) {
    final gridCols = w >= 900 ? 2 : 1;
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle(Icons.person_outline, '基本資料', '編輯身材數據，幫助 AI 更準確'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: -8,
                    children: [
                      _radio(title: '男性', value: 'male', groupValue: _profile.gender, onChanged: (v) => _markChanged(_profile.copyWith(gender: v!))),
                      _radio(title: '女性', value: 'female', groupValue: _profile.gender, onChanged: (v) => _markChanged(_profile.copyWith(gender: v!))),
                      _radio(title: '其他 / 不透露', value: 'other', groupValue: _profile.gender, onChanged: (v) => _markChanged(_profile.copyWith(gender: v!))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: gridCols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: w >= 900 ? 3.5 : 3.0,
                    children: [
                      _numField(label: '身高 (cm)', initial: _profile.height.toString(), onChanged: (v) => _markChanged(_profile.copyWith(height: _parseInt(v, _profile.height)))),
                      _numField(label: '體重 (kg)', initial: _profile.weight.toString(), onChanged: (v) => _markChanged(_profile.copyWith(weight: _parseInt(v, _profile.weight)))),
                      _numField(label: '肩寬 (cm)', initial: _profile.shoulderWidth.toString(), onChanged: (v) => _markChanged(_profile.copyWith(shoulderWidth: _parseInt(v, _profile.shoulderWidth)))),
                      _numField(label: '腰圍 (cm)', initial: _profile.waistline.toString(), onChanged: (v) => _markChanged(_profile.copyWith(waistline: _parseInt(v, _profile.waistline)))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _subTitle('版型偏好'),
                  Wrap(
                    spacing: 8,
                    children: [
                      _choiceChip('修身 (Slim)', _profile.fitPreference == 'slim', () => _markChanged(_profile.copyWith(fitPreference: 'slim'))),
                      _choiceChip('標準 (Regular)', _profile.fitPreference == 'regular', () => _markChanged(_profile.copyWith(fitPreference: 'regular'))),
                      _choiceChip('寬鬆 (Oversized)', _profile.fitPreference == 'oversized', () => _markChanged(_profile.copyWith(fitPreference: 'oversized'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  _subTitle('通勤方式'),
                  Wrap(
                    spacing: 8,
                    children: [
                      _choiceChip('大眾運輸', _profile.commuteMethod == 'public', () => _markChanged(_profile.copyWith(commuteMethod: 'public'))),
                      _choiceChip('開車', _profile.commuteMethod == 'car', () => _markChanged(_profile.copyWith(commuteMethod: 'car'))),
                      _choiceChip('步行/腳踏車', _profile.commuteMethod == 'walk', () => _markChanged(_profile.copyWith(commuteMethod: 'walk'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('騎機車通勤'),
                    subtitle: const Text('幫助推薦適合騎車的穿搭'),
                    value: _profile.hasMotorcycle,
                    onChanged: (v) => _markChanged(_profile.copyWith(hasMotorcycle: v)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleTab(BuildContext context, double w) {
    final selectedStyles = _selectedStyleIds;
    final displayedStyles = _allStyles().where((s) => selectedStyles.contains(s.id)).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle(Icons.palette_outlined, '風格偏好', '點選喜歡的風格，系統會自動分配權重'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          _tempSelected = [..._selectedStyleIds];
                          setState(() => _isStyleDialogOpen = true);
                          showDialog(context: context, builder: (_) => _styleDialog(context)).then((_) => setState(() => _isStyleDialogOpen = false));
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('更多風格選項'),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          if (_selectedStyleIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請先選擇至少一個風格')));
                            return;
                          }
                          final newWeights = _convertSelectedToWeights(_selectedStyleIds);
                          _markChanged(_profile.copyWith(styleWeights: newWeights));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已平均分配風格權重')));
                        },
                        icon: const Icon(Icons.balance),
                        label: const Text('平均分配'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _selectedStyleIds = [];
                          _markChanged(_profile.copyWith(styleWeights: _clearAllWeights()));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除所有風格權重')));
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('清除全部'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: displayedStyles.isEmpty
                        ? _emptyHint()
                        : Wrap(
                            spacing: 8,
                            runSpacing: -6,
                            children: displayedStyles.map((s) {
                              return InputChip(
                                label: Text(s.label),
                                onDeleted: () {
                                  final next = _selectedStyleIds.where((id) => id != s.id).toList();
                                  if (next.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('至少需要選擇一個風格')));
                                    return;
                                  }
                                  _selectedStyleIds = next;
                                  final newWeights = _convertSelectedToWeights(next);
                                  _markChanged(_profile.copyWith(styleWeights: newWeights));
                                },
                                avatar: s.isCustom ? const Icon(Icons.auto_awesome, size: 16) : null,
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _subTitle('顏色黑名單（不想穿的顏色）'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 12, runSpacing: 12, children: _colorTiles(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _styleDialog(BuildContext context) {
    final controller = _newStyleCtrl;

    List<_StyleOption> filtered(String q) {
      final all = _allStyles();
      if (q.trim().isEmpty) return all;
      final kw = q.trim().toLowerCase();
      return all.where((s) => s.label.toLowerCase().contains(kw) || s.id.toLowerCase().contains(kw)).toList();
    }

    final searchCtrl = TextEditingController();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: StatefulBuilder(
        builder: (context, setLocal) {
          final all = filtered(searchCtrl.text);
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('選擇您喜歡的風格', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('點選風格標籤，系統會自動為您分配權重', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  _subTitle('新增自訂風格'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          maxLength: 20,
                          decoration: const InputDecoration(
                            hintText: '輸入風格名稱（如：嘻哈、龐克）',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          onSubmitted: (_) => _addCustomStyle(controller, setLocal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(onPressed: () => _addCustomStyle(controller, setLocal), icon: const Icon(Icons.add), label: const Text('新增')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: '搜尋風格', border: OutlineInputBorder()),
                    onChanged: (_) => setLocal(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: -6,
                        children: all.map((s) {
                          final selected = _tempSelected.contains(s.id);
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(s.label),
                                if (s.isCustom) const SizedBox(width: 4),
                                if (s.isCustom) const Icon(Icons.auto_awesome, size: 14),
                              ],
                            ),
                            selected: selected,
                            onSelected: (_) {
                              setLocal(() {
                                if (selected) {
                                  _tempSelected.remove(s.id);
                                } else {
                                  _tempSelected.add(s.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('已選擇 ${_tempSelected.length} 個風格', style: const TextStyle(color: Colors.black54)),
                      const Spacer(),
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          if (_tempSelected.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請至少選擇一個風格')));
                            return;
                          }
                          setState(() {
                            _selectedStyleIds = [..._tempSelected];
                            final newWeights = _convertSelectedToWeights(_selectedStyleIds);
                            _markChanged(_profile.copyWith(styleWeights: newWeights));
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('確認選擇'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _addCustomStyle(TextEditingController controller, void Function(void Function()) setLocal) {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    final id = _slugify(name);
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('風格名稱不合法')));
      return;
    }
    final exists = _allStyles().any((s) => s.id == id);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('風格已存在')));
      return;
    }
    _customStyles.add(_StyleOption(id, name, isCustom: true));
    _tempSelected.add(id);
    controller.clear();
    setLocal(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已新增風格「$name」')));
  }

  List<Widget> _colorTiles(BuildContext context) {
    final items = [
      ('pink', '粉紅', const Color(0xFFF472B6)),
      ('purple', '紫色', const Color(0xFFA78BFA)),
      ('yellow', '黃色', const Color(0xFFFACC15)),
      ('orange', '橘色', const Color(0xFFF59E0B)),
      ('green', '綠色', const Color(0xFF4ADE80)),
      ('red', '紅色', const Color(0xFFEF4444)),
    ];

    bool isOff(String id) => _profile.colorBlacklist.contains(id);

    return items.map((e) {
      final id = e.$1;
      final label = e.$2;
      final color = e.$3;
      final off = isOff(id);
      return GestureDetector(
        onTap: () {
          final list = List<String>.of(_profile.colorBlacklist);
          off ? list.remove(id) : list.add(id);
          _markChanged(_profile.copyWith(colorBlacklist: list));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 64, height: 64, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
                if (off)
                  Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(width: 4, height: 72, color: Colors.red.shade700),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildNotificationsTab(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              _sectionTitle(Icons.notifications_outlined, '推播通知', '管理您想接收的通知類型'),
              SwitchListTile.adaptive(
                value: _dailyOutfit,
                onChanged: (v) => setState(() => _dailyOutfit = v),
                title: const Text('每日穿搭建議'),
                subtitle: const Text('每天早上收到穿搭推薦'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: _weatherAlert,
                onChanged: (v) => setState(() => _weatherAlert = v),
                title: const Text('天氣警報'),
                subtitle: const Text('極端天氣或溫度變化提醒'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: _rainReminder,
                onChanged: (v) => setState(() => _rainReminder = v),
                title: const Text('降雨提醒'),
                subtitle: const Text('下雨前提醒攜帶雨具'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: _communityLikes,
                onChanged: (v) => setState(() => _communityLikes = v),
                title: const Text('社群按讚'),
                subtitle: const Text('有人喜歡您的穿搭時通知'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: _communityComments,
                onChanged: (v) => setState(() => _communityComments = v),
                title: const Text('社群留言'),
                subtitle: const Text('有人評論您的穿搭時通知'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle(Icons.alternate_email, '電子信箱', '用於登入和接收重要通知'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email 已更新（示意）'))),
                    child: const Text('更新 Email'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle(Icons.lock_outline, '變更密碼', '定期更新密碼以保護帳號安全'),
                  const SizedBox(height: 8),
                  _pwdField(_pwdCurrentCtrl, '目前密碼'),
                  const SizedBox(height: 8),
                  _pwdField(_pwdNewCtrl, '新密碼（至少 6 個字元）'),
                  const SizedBox(height: 8),
                  _pwdField(_pwdConfirmCtrl, '確認新密碼'),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () {
                      final c = _pwdCurrentCtrl.text;
                      final n = _pwdNewCtrl.text;
                      final cf = _pwdConfirmCtrl.text;
                      if (c.isEmpty || n.isEmpty || cf.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請填寫所有密碼欄位')));
                        return;
                      }
                      if (n != cf) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新密碼不一致')));
                        return;
                      }
                      if (n.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密碼至少需要 6 個字元')));
                        return;
                      }
                      _pwdCurrentCtrl.clear();
                      _pwdNewCtrl.clear();
                      _pwdConfirmCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密碼已更新（示意）')));
                    },
                    child: const Text('更新密碼'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('登出帳號', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('登出此裝置上的帳號'),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('確定要登出嗎？'),
                            content: const Text('您需要重新登入才能繼續使用 WEAR 的功能。'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
                              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('確定登出')),
                            ],
                          ),
                        );
                        if (ok == true) widget.onLogout();
                      },
                      label: const Text('登出'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(child: Text(subtitle, style: const TextStyle(color: Colors.black54))),
      ],
    );
  }

  Widget _subTitle(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600));

  Widget _radio({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged),
        GestureDetector(onTap: () => onChanged(value), child: Text(title)),
      ],
    );
  }

  Widget _numField({required String label, required String initial, required ValueChanged<String> onChanged}) {
    return TextField(
      controller: TextEditingController(text: initial),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: ' ', border: OutlineInputBorder()).copyWith(labelText: label),
      onChanged: onChanged,
    );
  }

  Widget _pwdField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }

  Widget _emptyHint() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome, size: 28, color: Colors.black45),
            SizedBox(height: 8),
            Text('點擊「更多風格選項」開始選擇您喜歡的風格', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
