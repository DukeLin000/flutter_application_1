import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme/s_flow_design.dart'; // ✅ 引入設計系統

/// ---------------------------------------------------------------------------
/// Mock Data + Models (保持不變)
/// ---------------------------------------------------------------------------
class ClothingItem {
  final String id;
  final String subCategory;
  final String? brand;
  final String imageUrl;
  const ClothingItem({
    required this.id,
    required this.subCategory,
    this.brand,
    this.imageUrl = '',
  });
}

class Outfit {
  final String id;
  final ClothingItem top;
  final ClothingItem bottom;
  final ClothingItem shoes;
  final String occasion;
  final (int min, int max) suitableTemp;
  final bool isRainSuitable;
  final String reason;
  final int colorHarmony;
  final int proportionScore;

  const Outfit({
    required this.id,
    required this.top,
    required this.bottom,
    required this.shoes,
    required this.occasion,
    required this.suitableTemp,
    required this.isRainSuitable,
    required this.reason,
    required this.colorHarmony,
    required this.proportionScore,
  });
}

const mockClothingItems = <ClothingItem>[
  ClothingItem(id: 'c1', subCategory: '針織衫', brand: 'Uniqlo'),
  ClothingItem(id: 'c2', subCategory: '直筒褲', brand: 'GU'),
  ClothingItem(id: 'c3', subCategory: '運動鞋', brand: 'Nike'),
  ClothingItem(id: 'c4', subCategory: '機能外套', brand: 'H&M'),
  ClothingItem(id: 'c5', subCategory: '卡其褲', brand: 'ZARA'),
  ClothingItem(id: 'c6', subCategory: '樂福鞋', brand: 'Dr. Martens'),
];

/// ---------------------------------------------------------------------------
/// AI Page (S-FLOW RWD)
/// ---------------------------------------------------------------------------
class AIPage extends StatefulWidget {
  // ✅ 修正 1: 接收全域顏色
  final SFlowColors? currentColors;

  const AIPage({
    super.key,
    this.currentColors,
  });

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  double temperature = 24;
  bool isRaining = false;
  bool isCommute = false;
  final Set<String> selectedOccasions = {'casual'};

  late List<Outfit> results;

  // ✅ 修正 2: 改為 Getter，動態使用傳入顏色，預設為紫色 (深色背景)
  SFlowColors get colors => widget.currentColors ?? SFlowThemes.purple;

  @override
  void initState() {
    super.initState();
    results = [
      Outfit(
        id: 'ai1',
        top: mockClothingItems[0],
        bottom: mockClothingItems[1],
        shoes: mockClothingItems[2],
        occasion: '休閒',
        suitableTemp: (20, 28),
        isRainSuitable: false,
        reason: '舒適透氣，適合微熱天氣',
        colorHarmony: 90,
        proportionScore: 87,
      ),
    ];
  }

  // ✅ 修正 3: 監聽父層顏色變化
  @override
  void didUpdateWidget(AIPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColors != widget.currentColors) {
      setState(() {}); 
    }
  }

  // ---------------- RWD helpers ----------------
  double _containerMaxWidth(double w) {
    if (w >= 1600) return 1200;
    if (w >= 1200) return 1100;
    if (w >= 900) return 900;
    if (w >= 600) return 760;
    return w - 24;
  }

  int _gridCols(double w) {
    if (w >= 1200) return 3;
    if (w >= 900) return 2;
    return 1;
  }

  // ---------------- Actions ----------------
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: colors.text)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.glassBorder),
        ),
      ),
    );
  }

  void _handleGenerate() {
    _snack('AI 正在為你生成穿搭建議...');
    // TODO: 接你的 AI API，塞回 results
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isLg = w >= 1200;

    return Scaffold(
      backgroundColor: Colors.transparent, // ★ 透明背景
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('AI STYLIST', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(isLg ? 24 : 16, 16, isLg ? 24 : 16, isLg ? 24 : 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 條件設定卡
                _GlassConditionsCard(
                  temperature: temperature,
                  isRaining: isRaining,
                  isCommute: isCommute,
                  selectedOccasions: selectedOccasions,
                  colors: colors,
                  onTemperatureChanged: (v) => setState(() => temperature = v),
                  onToggleRain: (v) => setState(() => isRaining = v),
                  onToggleCommute: (v) => setState(() => isCommute = v),
                  onToggleOccasion: (id) => setState(() {
                    selectedOccasions.contains(id)
                        ? selectedOccasions.remove(id)
                        : selectedOccasions.add(id);
                  }),
                  onGenerate: _handleGenerate,
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI 推薦 (${results.length})', 
                      style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    OutlinedButton.icon(
                      onPressed: _handleGenerate,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.glassBorder),
                        foregroundColor: colors.text,
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('重新生成'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 推薦卡片
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = _gridCols(c.maxWidth);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: results.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 4 / 3.2,
                      ),
                      itemBuilder: (_, i) => _GlassOutfitRecommendCard(
                        outfit: results[i],
                        colors: colors,
                        onSave: () => _snack('已儲存'),
                        onShare: () => _snack('已分享'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
                
                // 理由說明
                _GlassReasonCard(
                  temperature: temperature,
                  isRaining: isRaining,
                  colors: colors,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 玻璃條件設定 Card
class _GlassConditionsCard extends StatelessWidget {
  const _GlassConditionsCard({
    required this.temperature,
    required this.isRaining,
    required this.isCommute,
    required this.selectedOccasions,
    required this.colors,
    required this.onTemperatureChanged,
    required this.onToggleRain,
    required this.onToggleCommute,
    required this.onToggleOccasion,
    required this.onGenerate,
  });

  final double temperature;
  final bool isRaining;
  final bool isCommute;
  final Set<String> selectedOccasions;
  final SFlowColors colors;
  final ValueChanged<double> onTemperatureChanged;
  final ValueChanged<bool> onToggleRain;
  final ValueChanged<bool> onToggleCommute;
  final ValueChanged<String> onToggleOccasion;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final occasions = const [
      ('casual', '休閒'),
      ('office', '上班'),
      ('sport', '運動'),
      ('date', '約會'),
      ('formal', '正式'),
    ];

    return GlassContainer(
      colors: colors,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: colors.primary),
              const SizedBox(width: 8),
              Text('設定條件', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          // 場合
          Text('場合', style: TextStyle(color: colors.textDim, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (id, label) in occasions)
                GestureDetector(
                  onTap: () => onToggleOccasion(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedOccasions.contains(id) ? colors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      border: Border.all(color: selectedOccasions.contains(id) ? colors.primary : Colors.white10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label, 
                      style: TextStyle(
                        color: selectedOccasions.contains(id) ? colors.primary : colors.textDim,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // 溫度
          Row(
            children: [
              Icon(Icons.thermostat, size: 18, color: colors.secondary),
              const SizedBox(width: 8),
              Text('體感溫度: ${temperature.round()}°C', style: TextStyle(color: colors.text)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.primary,
              inactiveTrackColor: Colors.white10,
              thumbColor: colors.primary,
              overlayColor: colors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: temperature,
              min: 10,
              max: 35,
              divisions: 25,
              label: '${temperature.round()}°C',
              onChanged: onTemperatureChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10°C', style: TextStyle(fontSize: 12, color: colors.textDim)), 
              Text('35°C', style: TextStyle(fontSize: 12, color: colors.textDim))
            ],
          ),
          const SizedBox(height: 16),

          // 開關
          _GlassSwitch(
            value: isRaining, 
            onChanged: onToggleRain, 
            label: '下雨天', 
            icon: Icons.water_drop_outlined,
            colors: colors,
          ),
          const SizedBox(height: 8),
          _GlassSwitch(
            value: isCommute, 
            onChanged: onToggleCommute, 
            label: '騎機車通勤', 
            icon: Icons.motorcycle_outlined,
            colors: colors,
          ),

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onGenerate,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('生成穿搭建議', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final IconData icon;
  final SFlowColors colors;

  const _GlassSwitch({
    required this.value, 
    required this.onChanged, 
    required this.label, 
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? colors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? colors.primary.withOpacity(0.3) : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: value ? colors.primary : colors.textDim),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: colors.text))),
            Switch(
              value: value, 
              onChanged: onChanged,
              activeColor: colors.primary,
              activeTrackColor: colors.primary.withOpacity(0.3),
              inactiveTrackColor: Colors.white10,
            ),
          ],
        ),
      ),
    );
  }
}

/// 玻璃推薦卡片
class _GlassOutfitRecommendCard extends StatelessWidget {
  const _GlassOutfitRecommendCard({
    required this.outfit, 
    required this.onSave, 
    required this.onShare,
    required this.colors,
  });
  
  final Outfit outfit;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final SFlowColors colors;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: _ImagePlaceholder()),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('場合：${outfit.occasion}', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(outfit.reason, style: TextStyle(color: colors.textDim, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag('配色 ${outfit.colorHarmony}%', colors),
                    _Tag('比例 ${outfit.proportionScore}%', colors),
                    _Tag('適溫 ${outfit.suitableTemp.$1}-${outfit.suitableTemp.$2}°C', colors),
                    if (outfit.isRainSuitable) _Tag('雨天OK', colors),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ActionButton(icon: Icons.bookmark_border, label: '收藏', onTap: onSave, colors: colors),
                    const SizedBox(width: 8),
                    _ActionButton(icon: Icons.ios_share, label: '分享', onTap: onShare, colors: colors),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final SFlowColors colors;
  const _Tag(this.text, this.colors);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: colors.textDim, fontSize: 10)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final SFlowColors colors;
  
  const _ActionButton({required this.icon, required this.label, required this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.secondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: colors.textDim, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(child: Icon(Icons.checkroom_outlined, size: 64, color: Colors.white24)),
    );
  }
}

/// 玻璃理由說明 Card
class _GlassReasonCard extends StatelessWidget {
  const _GlassReasonCard({required this.temperature, required this.isRaining, required this.colors});
  final double temperature;
  final bool isRaining;
  final SFlowColors colors;

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c) => Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.withOpacity(0.5), blurRadius: 4)]));

    return GlassContainer(
      colors: colors,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI 分析報告', style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _reasonRow(dot(Colors.greenAccent), '配色和諧度 90%', '白色與黑色為經典配色，視覺平衡佳'),
          const SizedBox(height: 10),
          _reasonRow(dot(Colors.greenAccent), '版型比例良好', '上寬下窄，修飾身材比例'),
          const SizedBox(height: 10),
          _reasonRow(dot(Colors.blueAccent), '體感建議', '當前溫度 ${temperature.round()}°C，建議穿著透氣材質${isRaining ? '，雨天建議攜帶防水外套' : ''}'),
        ],
      ),
    );
  }

  Widget _reasonRow(Widget leading, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 6), child: leading),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(color: colors.textDim, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}