import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kDebugMode

import 'page/onboarding_page.dart';
import 'page/home_page.dart';
import 'page/community_page.dart';
import 'page/wardrobe_page.dart';
import 'page/ai_page.dart';
import 'page/profile_page.dart';
import 'page/profilepage/capsule_page.dart';
import 'page/profilepage/shop_page.dart';

import 'api/api_client.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      // Onboarding -> 完成後導入主殼 (_RootShell)
      home: OnboardingPage(
        onComplete: (profile) async {
          final nav = navigatorKey.currentState;
          if (nav == null || !nav.mounted) return;

          // 顯示 Loading 避免連點 & 提供回饋
          showDialog(
            context: nav.context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          try {
            final saved = await ApiClient.I.saveProfile(profile.toJson());
            if (kDebugMode) {
              debugPrint('後端已接收：$saved');
            }
          } catch (e) {
            if (nav.mounted) {
              ScaffoldMessenger.of(nav.context).showSnackBar(
                SnackBar(content: Text('無法連線後端：$e')),
              );
            }
          } finally {
            if (nav.mounted) Navigator.of(nav.context).pop(); // 關閉 Loading
          }

          if (nav.mounted) {
            // 清空返回堆疊，避免返回回到 Onboarding
            nav.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const _RootShell()),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}

/// App 殼：底部導覽（Home / Community / Wardrobe / AI / Profile）
class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _index = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  void _notifyDev(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // 開啟膠囊衣櫥頁
  void _openCapsule() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CapsulePage()),
    );
  }

  // 開啟在地可購
  void _openShop() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShopPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        key: const PageStorageKey('home'),
        hasItems: true, // TODO: 改成由狀態管理決定
        onAddItems: () => debugPrint('前往衣櫃新增單品'),
      ),
      const CommunityPage(key: PageStorageKey('community')),
      const WardrobePage(key: PageStorageKey('wardrobe')),
      const AIPage(key: PageStorageKey('ai')),
      // Profile 需要 onNavigate，以便從個人中心跳到其他頁
      ProfilePage(
        key: const PageStorageKey('profile'),
        onNavigate: (page) {
          switch (page) {
            case 'capsule':
              _openCapsule();
              break;
            case 'shop':
              _openShop();
              break;
            default:
              _notifyDev('尚未實作：$page');
          }
        },
      ),
    ];

    return PageStorage(
      bucket: _bucket,
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '首頁',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: '社群',
            ),
            NavigationDestination(
              icon: Icon(Icons.checkroom_outlined),
              selectedIcon: Icon(Icons.checkroom),
              label: '衣櫃',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'AI',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '個人',
            ),
          ],
        ),
        // 開發專用：健康檢查 FAB，發版時自動關閉
        floatingActionButton: kDebugMode
            ? FloatingActionButton(
                onPressed: () async {
                  final ok = await ApiClient.I.ping();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? '已連線到後端（200）' : '後端不通')),
                  );
                  if (kDebugMode) {
                    debugPrint('API_BASE_URL = ${ApiClient.I.baseUrl}');
                  }
                },
                child: const Icon(Icons.wifi_tethering),
              )
            : null,
      ),
    );
  }
}
