import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Mock Data + Models (可替換為你的實際型別)
/// ---------------------------------------------------------------------------
class ClothingItem {
  final String id;
  final String subCategory; // e.g. 針織衫、直筒褲
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
  final String occasion; // 休閒、上班...
  final (int min, int max) suitableTemp; // (min,max)
  final bool isRainSuitable;
  final String reason;
  final int colorHarmony; // 0-100
  final int proportionScore; // 0-100

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
/// AI 智能出裝（Web / iPhone 全系列 / Android 各尺寸 RWD）
/// ---------------------------------------------------------------------------
class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  double temperature = 24;
  bool isRaining = false;
  bool isCommute = false;
  final Set<String> selectedOccasions = {'casual'};

  late List<Outfit> results;

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

  // ---------------- RWD helpers ----------------
  double _containerMaxWidth(double w) {
    if (w >= 1600) return 1200; // very wide desktop
    if (w >= 1200) return 1100; // desktop
    if (w >= 900) return 900;   // tablet
    if (w >= 600) return 760;   // small tablet / landscape
    return w - 24;              // phones，保留邊距
  }

  int _gridCols(double w) {
    if (w >= 1200) return 3; // lg
    if (w >= 900) return 2;  // md
    return 1;                // sm
  }

  // ---------------- Actions ----------------
  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _handleGenerate() {
    _snack('AI 正在為你生成穿搭建議...');
    // TODO: 接你的 AI API，塞回 results
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('AI 智能出裝')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _containerMaxWidth(w)),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(w >= 1200 ? 24 : 16, 16, w >= 1200 ? 24 : 16, w >= 1200 ? 24 : 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ConditionsCard(
                  temperature: temperature,
                  isRaining: isRaining,
                  isCommute: isCommute,
                  selectedOccasions: selectedOccasions,
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

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AI 推薦 (${results.length})', style: Theme.of(context).textTheme.titleLarge),
                    OutlinedButton.icon(
                      onPressed: _handleGenerate,
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
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 4 / 3,
                      ),
                      itemBuilder: (_, i) => _OutfitRecommendCard(
                        outfit: results[i],
                        onSave: () => _snack('已儲存'),
                        onShare: () => _snack('已分享'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
                _ReasonCard(
                  temperature: temperature,
                  isRaining: isRaining,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 條件設定 Card
class _ConditionsCard extends StatelessWidget {
  const _ConditionsCard({
    required this.temperature,
    required this.isRaining,
    required this.isCommute,
    required this.selectedOccasions,
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
  final ValueChanged<double> onTemperatureChanged;
  final ValueChanged<bool> onToggleRain;
  final ValueChanged<bool> onToggleCommute;
  final ValueChanged<String> onToggleOccasion;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final occasions = const [
      ('casual', '休閒'),
      ('office', '上班'),
      ('sport', '運動'),
      ('date', '約會'),
      ('formal', '正式'),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: 8),
                Text('設定條件', style: t.titleLarge),
              ],
            ),
            const SizedBox(height: 16),

            // 場合
            Text('場合', style: t.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, label) in occasions)
                  ChoiceChip(
                    label: Text(label),
                    selected: selectedOccasions.contains(id),
                    onSelected: (_) => onToggleOccasion(id),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 溫度
            Row(
              children: [
                const Icon(Icons.thermostat, size: 18),
                const SizedBox(width: 8),
                Text('體感溫度: ${temperature.round()}°C'),
              ],
            ),
            Slider(
              value: temperature,
              min: 10,
              max: 35,
              divisions: 25,
              label: '${temperature.round()}°C',
              onChanged: onTemperatureChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [Text('10°C', style: TextStyle(fontSize: 12, color: Colors.grey)), Text('35°C', style: TextStyle(fontSize: 12, color: Colors.grey))],
            ),
            const SizedBox(height: 8),

            // 天氣開關
            SwitchListTile(
              value: isRaining,
              onChanged: onToggleRain,
              title: const Text('下雨天'),
              secondary: const Icon(Icons.water_drop_outlined),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: isCommute,
              onChanged: onToggleCommute,
              title: const Text('騎機車通勤'),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('生成穿搭建議'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 推薦穿搭卡片（自洽版，若你已有共用 Card 可替換）
class _OutfitRecommendCard extends StatelessWidget {
  const _OutfitRecommendCard({required this.outfit, required this.onSave, required this.onShare});
  final Outfit outfit;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 圖像區（示意）
          const Expanded(child: _ImagePlaceholder()),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('場合：${outfit.occasion}', style: t.titleMedium),
                const SizedBox(height: 4),
                Text(outfit.reason, style: t.bodySmall?.copyWith(color: Colors.grey[700])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(label: Text('配色 ${outfit.colorHarmony}%'), visualDensity: VisualDensity.compact),
                    Chip(label: Text('比例 ${outfit.proportionScore}%'), visualDensity: VisualDensity.compact),
                    Chip(label: Text('適溫 ${outfit.suitableTemp.$1}-${outfit.suitableTemp.$2}°C'), visualDensity: VisualDensity.compact),
                    if (outfit.isRainSuitable) const Chip(label: Text('雨天OK'), visualDensity: VisualDensity.compact),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(onPressed: onSave, icon: const Icon(Icons.bookmark_border, size: 18), label: const Text('收藏')),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(onPressed: onShare, icon: const Icon(Icons.ios_share, size: 18), label: const Text('分享')),
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Icon(Icons.checkroom_outlined, size: 64, color: Colors.black54)),
    );
  }
}

/// 理由說明 Card
class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.temperature, required this.isRaining});
  final double temperature;
  final bool isRaining;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget dot(Color c) => Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('理由說明', style: t.titleLarge),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              dot(Colors.green), const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('配色和諧度 90%'),
                SizedBox(height: 2),
                Text('白色與黑色為經典配色，視覺平衡佳', style: TextStyle(color: Colors.grey)),
              ])),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              dot(Colors.green), const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('版型比例良好'),
                SizedBox(height: 2),
                Text('上寬下窄，修飾身材比例', style: TextStyle(color: Colors.grey)),
              ])),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              dot(Colors.blue), const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('體感建議'),
                const SizedBox(height: 2),
                Text('當前溫度 ${temperature.round()}°C，建議穿著透氣材質${isRaining ? '，雨天建議攜帶防水外套' : ''}',
                    style: const TextStyle(color: Colors.grey)),
              ])),
            ]),
          ],
        ),
      ),
    );
  }
}
