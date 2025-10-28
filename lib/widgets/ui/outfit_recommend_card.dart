// lib/widgets/outfit_recommend_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';

/// ====== 簡化資料模型（對齊你在 TS 的結構）======
/// 單件衣物（只保留本卡片會用到的欄位）
class ClothingPiece {
  final String imageUrl;     // 可為 http(s) 或 data:image/...;base64,XXXX
  final String subCategory;  // 顯示用名稱（如：T 恤、牛仔褲）
  const ClothingPiece({required this.imageUrl, required this.subCategory});
}

/// 穿搭組合
class Outfit {
  final ClothingPiece? outerwear;
  final ClothingPiece? top;
  final ClothingPiece? bottom;
  final ClothingPiece? shoes;
  final String? reason;           // 推薦理由
  final int colorHarmony;         // 0..100
  final int proportionScore;      // 0..100
  const Outfit({
    this.outerwear,
    this.top,
    this.bottom,
    this.shoes,
    this.reason,
    this.colorHarmony = 0,
    this.proportionScore = 0,
  });
}

/// ====== Flutter 版 OutfitRecommendCard ======
class OutfitRecommendCard extends StatelessWidget {
  final Outfit outfit;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const OutfitRecommendCard({
    super.key,
    required this.outfit,
    this.onSave,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    // RWD：依容器寬度調整圖塊尺寸與間距
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final double pieceSize = _pieceSize(w);
        final double gap = _gapSize(w);

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 圖片區（與 React 的 aspect-[3/4] 對齊）
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  color: const Color(0xFFF3F4F6), // bg-gray-100
                  child: Center(
                    child: SingleChildScrollView(
                      // 避免超小螢幕時溢出
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (outfit.outerwear != null) ...[
                            _PieceBox(size: pieceSize, piece: outfit.outerwear!),
                            SizedBox(height: gap),
                          ],
                          if (outfit.top != null) ...[
                            _PieceBox(size: pieceSize, piece: outfit.top!),
                            SizedBox(height: gap),
                          ],
                          if (outfit.bottom != null) ...[
                            _PieceBox(size: pieceSize, piece: outfit.bottom!),
                            SizedBox(height: gap),
                          ],
                          if (outfit.shoes != null)
                            _PieceBox(
                              size: (pieceSize * 0.75).clamp(56, 120),
                              piece: outfit.shoes!,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 資訊區
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (outfit.reason != null && outfit.reason!.trim().isNotEmpty)
                      _Badge(text: outfit.reason!.trim()),
                    if (outfit.reason != null && outfit.reason!.trim().isNotEmpty)
                      const SizedBox(height: 10),

                    // 評分列
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '配色和諧 ${outfit.colorHarmony}%',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                        Text('•', style: TextStyle(color: Colors.grey[500])),
                        Text(
                          '比例 ${outfit.proportionScore}%',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 按鈕列（儲存 + 分享）
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onSave,
                            icon: const Icon(Icons.bookmark_border, size: 18),
                            label: const Text('儲存'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: onShare,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                          child: const Icon(Icons.ios_share, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 依寬度調整尺寸（RWD）
  double _pieceSize(double w) {
    if (w >= 1200) return 140; // desktop 寬
    if (w >= 900) return 128;  // desktop 窄 / 大平板
    if (w >= 600) return 112;  // 平板
    if (w >= 380) return 96;   // 一般手機
    return 84;                 // 小手機
  }

  double _gapSize(double w) {
    if (w >= 1200) return 14;
    if (w >= 900) return 12;
    if (w >= 600) return 10;
    return 8;
  }
}

/// 單件圖塊（白底、圓角、陰影，內含圖片）
/// 與 React 版的  w-32 h-32 bg-white rounded-lg shadow-sm p-2 對齊
class _PieceBox extends StatelessWidget {
  final double size;
  final ClothingPiece piece;
  const _PieceBox({required this.size, required this.piece});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _ImageWithFallback(url: piece.imageUrl, alt: piece.subCategory),
      ),
    );
  }
}

/// 取代 React 的 <Badge variant="secondary">
class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

/// ImageWithFallback：支援 http(s) 與 dataURL，失敗時顯示佔位
class _ImageWithFallback extends StatelessWidget {
  final String url;
  final String alt;
  const _ImageWithFallback({required this.url, required this.alt});

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: Icon(Icons.image_outlined, color: Colors.black54)),
    );

    if (url.isEmpty) return placeholder;

    // 支援 data:image/png;base64,XXXX
    if (url.startsWith('data:image')) {
      try {
        final comma = url.indexOf(',');
        final b64 = comma >= 0 ? url.substring(comma + 1) : '';
        final bytes = base64Decode(b64);
        return Image.memory(bytes, fit: BoxFit.contain, errorBuilder: (_, __, ___) => placeholder);
      } catch (_) {
        return placeholder;
      } 
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      // Web/行動裝置皆 OK 的載入/錯誤處理
      loadingBuilder: (c, w, p) => p == null ? w : placeholder,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
