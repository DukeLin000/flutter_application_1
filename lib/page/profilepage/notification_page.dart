// lib/page/profilepage/notification_page.dart
import 'package:flutter/material.dart';

enum NotificationType { weather, outfit, social, wardrobe, system }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? imageUrl;
  final String? actionLabel;
  final String? actionLink;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.imageUrl,
    this.actionLabel,
    this.actionLink,
    this.isRead = false,
  });
}

final List<AppNotification> kMockNotifications = [
  AppNotification(
    id: 'n1',
    type: NotificationType.weather,
    title: '今日下雨機率 70%',
    message: '建議帶雨具，穿防潑水外套。',
    timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
    actionLabel: '查看天氣',
    actionLink: 'weather',
  ),
  AppNotification(
    id: 'n2',
    type: NotificationType.outfit,
    title: 'AI 出裝完成',
    message: '依你的通勤方式與黑名單色生成 3 套建議。',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    actionLabel: '去看搭配',
    actionLink: 'ai-outfit',
  ),
  AppNotification(
    id: 'n3',
    type: NotificationType.social,
    title: '阿哲按讚了你的分享',
    message: '機能外套＋赤耳丹寧獲得 12 個讚。',
    timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    isRead: true,
  ),
  AppNotification(
    id: 'n4',
    type: NotificationType.wardrobe,
    title: '衣櫃提醒',
    message: '你的白色 T 恤穿搭使用率高，建議補貨 1 件。',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    actionLabel: '去逛逛',
    actionLink: 'shop',
  ),
  AppNotification(
    id: 'n5',
    type: NotificationType.system,
    title: '系統更新',
    message: '已改善 Web 登入狀況並新增 Dark Mode。',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

double _maxContentWidth(double w) {
  if (w >= 1600) return 1100;
  if (w >= 1200) return 1000;
  if (w >= 900) return 820;
  if (w >= 600) return 560;
  return w - 24;
}

String _formatRelativeTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return '剛剛';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
  if (diff.inHours < 24) return '${diff.inHours} 小時前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return '${t.month.toString().padLeft(2, '0')}/${t.day.toString().padLeft(2, '0')}';
}

IconData _typeIcon(NotificationType t) => switch (t) {
      NotificationType.weather => Icons.cloud_queue,
      NotificationType.outfit => Icons.auto_awesome,
      NotificationType.social => Icons.people_alt_outlined,
      NotificationType.wardrobe => Icons.shopping_bag_outlined,
      NotificationType.system => Icons.info_outline,
    };

Color _typeBgColor(BuildContext ctx, NotificationType t) {
  final c = Theme.of(ctx).colorScheme;
  return switch (t) {
    NotificationType.weather => c.primaryContainer.withOpacity(.35),
    NotificationType.outfit => c.tertiaryContainer.withOpacity(.40),
    NotificationType.social => Colors.pinkAccent.withOpacity(.20),
    NotificationType.wardrobe => Colors.greenAccent.withOpacity(.20),
    NotificationType.system => Colors.grey.withOpacity(.20),
  };
}

String _typeLabel(NotificationType t) => switch (t) {
      NotificationType.weather => '天氣',
      NotificationType.outfit => '穿搭',
      NotificationType.social => '社群',
      NotificationType.wardrobe => '衣櫃',
      NotificationType.system => '系統',
    };

class NotificationPage extends StatefulWidget {
  const NotificationPage({
    super.key,
    required this.onBack,
    this.onNavigate,
  });

  final VoidCallback onBack;
  final void Function(String tab)? onNavigate;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late List<AppNotification> _notifications;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _notifications = List<AppNotification>.from(kMockNotifications);
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAsRead(String id) {
    setState(() {
      final i = _notifications.indexWhere((n) => n.id == id);
      if (i != -1) _notifications[i].isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    _snack('已將所有通知標記為已讀');
  }

  void _deleteOne(String id) {
    setState(() => _notifications.removeWhere((n) => n.id == id));
    _snack('已刪除通知');
  }

  void _clearAll() {
    setState(() => _notifications.clear());
    _snack('已清空所有通知');
  }

  void _handleAction(AppNotification n) {
    _markAsRead(n.id);
    if (n.actionLink != null && widget.onNavigate != null) {
      widget.onNavigate!(n.actionLink!);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Iterable<AppNotification> get _filtered {
    if (_filter == 'all') return _notifications;
    final t = NotificationType.values
        .firstWhere((e) => e.name == _filter, orElse: () => NotificationType.system);
    return _notifications.where((n) => n.type == t);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            // IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
            const SizedBox(width: 4),
            const Icon(Icons.notifications_none),
            const SizedBox(width: 8),
            const Text('通知中心'),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              label: const Text('全部已讀'),
            ),
          if (_notifications.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('清空'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _maxContentWidth(w)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _FilterRow(
                  allCount: _notifications.length,
                  unreadCount: _unreadCount,
                  current: _filter,
                  countsByType: Map.fromEntries(
                    NotificationType.values.map(
                      (t) => MapEntry(
                        t,
                        _notifications.where((n) => n.type == t).length,
                      ),
                    ),
                  ),
                  onSelect: (key) => setState(() => _filter = key),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _filtered.isEmpty
                    ? _EmptyState(filter: _filter)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemBuilder: (_, i) {
                          final n = _filtered.elementAt(i);
                          return _NotificationCard(
                            n: n,
                            onDelete: () => _deleteOne(n.id),
                            onMarkRead: () => _markAsRead(n.id),
                            onAction: () => _handleAction(n),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: _filtered.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.allCount,
    required this.unreadCount,
    required this.current,
    required this.countsByType,
    required this.onSelect,
  });

  final int allCount;
  final int unreadCount;
  final String current;
  final Map<NotificationType, int> countsByType;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      ChoiceChip(
        label: Text('全部 ($allCount)'),
        selected: current == 'all',
        onSelected: (_) => onSelect('all'),
      ),
      for (final t in NotificationType.values)
        if (countsByType[t]! > 0)
          ChoiceChip(
            label: Text('${_typeLabel(t)} (${countsByType[t]})'),
            selected: current == t.name,
            onSelected: (_) => onSelect(t.name),
          ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('$unreadCount 則未讀通知',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            children: chips
                .map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.n,
    required this.onDelete,
    required this.onMarkRead,
    required this.onAction,
  });

  final AppNotification n;
  final VoidCallback onDelete;
  final VoidCallback onMarkRead;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final border = n.isRead
        ? BorderSide(color: Colors.grey.shade300)
        : BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(.35));

    return Card(
      elevation: n.isRead ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: border,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeadingIcon(n: n),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontWeight:
                                    n.isRead ? FontWeight.w500 : FontWeight.w700,
                              ),
                            ),
                            _SmallTag(text: _typeLabel(n.type)),
                            if (!n.isRead) const _UnreadDot(),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        tooltip: '刪除',
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatRelativeTime(n.timestamp),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      if (!n.isRead)
                        TextButton(onPressed: onMarkRead, child: const Text('標記已讀')),
                      if (n.actionLabel != null)
                        OutlinedButton(onPressed: onAction, child: Text(n.actionLabel!)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.n});
  final AppNotification n;

  @override
  Widget build(BuildContext context) {
    final bg = _typeBgColor(context, n.type);
    final icon = _typeIcon(n.type);

    return n.imageUrl != null
        ? CircleAvatar(radius: 24, backgroundImage: NetworkImage(n.imageUrl!))
        : Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 26),
          );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text('',
          // 透過 builder 動態換字，這裡先保留佔位避免字級閃爍
          ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration:
            const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final String filter;

  @override
  Widget build(BuildContext context) {
    final label = filter == 'all'
        ? '目前沒有任何通知'
        : '目前沒有${_typeLabel(NotificationType.values.firstWhere(
              (e) => e.name == filter,
              orElse: () => NotificationType.system,
            ))}相關通知';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text('沒有通知', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
