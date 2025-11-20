import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Model：對應原本的 Notification 介面
/// ---------------------------------------------------------------------------
class AppNotification {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime timestamp;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.timestamp,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] == true,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'isRead': isRead,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// ---------------------------------------------------------------------------
/// RWD NotificationWidget
///
/// 使用方式：
/// NotificationWidget(
///   notifications: yourList,
///   onViewAll: () {
///     // 導到通知頁 or 開啟 Dialog
///   },
///   onDismiss: (id) {
///     // 更新狀態為已讀 / 從列表移除
///   },
/// )
/// ---------------------------------------------------------------------------
class NotificationWidget extends StatelessWidget {
  final List<AppNotification> notifications;
  final VoidCallback onViewAll;
  final void Function(String id)? onDismiss;

  const NotificationWidget({
    super.key,
    required this.notifications,
    required this.onViewAll,
    this.onDismiss,
  });

  /// 對應原本的 formatTime(timestamp: string)
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    final minutes = diff.inMinutes;
    final hours = diff.inHours;

    if (minutes < 1) return '剛剛';
    if (minutes < 60) return '$minutes 分鐘前';
    if (hours < 24) return '$hours 小時前';

    // 類似 toLocaleDateString('zh-TW', { month: 'short', day: 'numeric' })
    final month = timestamp.month;
    final day = timestamp.day;
    // 簡單顯示：例如「3月5日」
    return '${month}月$day日';
  }

  @override
  Widget build(BuildContext context) {
    // 未讀的最新 3 則
    final recentUnread = notifications.where((n) => !n.isRead).take(3).toList();

    if (recentUnread.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 最大寬度控制：大螢幕時置中、手機則佔滿
        final double maxWidth =
            constraints.maxWidth > 720 ? 720 : constraints.maxWidth;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, recentUnread.length),
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(recentUnread.length, (index) {
                        final n = recentUnread[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == recentUnread.length - 1 ? 0 : 8,
                          ),
                          child: _buildNotificationItem(context, n),
                        );
                      }),
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

  /// Header：圖示 + 標題 + 未讀 Badge + 查看全部
  Widget _buildHeader(BuildContext context, int recentCount) {
    final int unreadTotal =
        notifications.where((n) => !n.isRead).length;

    return Row(
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications_none,
              size: 20,
              color: Colors.blue[600],
            ),
            const SizedBox(width: 8),
            Text(
              '最新通知',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(width: 4),
            // Badge（未讀數）
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unreadTotal.toString(),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            foregroundColor: Colors.blue[700],
          ),
          child: const Text(
            '查看全部',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// 單一通知卡片
  Widget _buildNotificationItem(BuildContext context, AppNotification n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue[100]!),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 內容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題 + 小藍點
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 內容（最多兩行）
                Text(
                  n.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 時間
                Text(
                  _formatTime(n.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => onDismiss?.call(n.id),
              icon: const Icon(Icons.close, size: 16),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              splashRadius: 18,
            ),
          ],
        ],
      ),
    );
  }
}
