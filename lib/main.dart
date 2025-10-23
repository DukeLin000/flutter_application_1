import 'package:flutter/material.dart';
import 'page/onboarding_page.dart';
import 'page/home_page.dart';
import 'page/community_page.dart';
import 'page/wardrobe_page.dart';
import 'page/ai_page.dart';
import 'page/profile_page.dart';
// ✅ Profile 子資料夾路由
import 'page/profilepage/capsule_page.dart';
import 'page/profilepage/shop_page.dart';

// ✅ 新增：API client
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
      // 先走 Onboarding，完成後導入底部導覽殼
      home: OnboardingPage(
        onComplete: (profile) async {
          try {
            // 將 Onboarding 蒐集到的 profile 上傳到 Spring Boot
            final saved = await ApiClient.I.saveProfile(profile.toJson());
            debugPrint('後端已接收：$saved');
          } catch (e) {
            debugPrint('上傳失敗：$e');
            final ctx = navigatorKey.currentContext;
            if (ctx != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('無法連線後端：$e')),
              );
            }
          }

          navigatorKey.currentState!.pushReplacement(
            MaterialPageRoute(builder: (_) => const _RootShell()),
          );
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

  void _notifyDev(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ✅ 開啟膠囊衣櫥頁（lib/page/profilepage/capsule_page.dart）
  void _openCapsule() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CapsulePage()),
    );
  }

  // ✅ 開啟在地可購（lib/page/profilepage/shop_page.dart）
  void _openShop() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShopPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        hasItems: true, // 沒資料時改成 false 會顯示空狀態
        onAddItems: () => debugPrint('前往衣櫃新增單品'),
      ),
      const CommunityPage(),
      const WardrobePage(),
      const AIPage(),
      // Profile 需要 onNavigate，以便從個人中心跳到其他頁
      ProfilePage(
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

    return Scaffold(
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
      // ✅ 新增：一鍵測後端連線（/api/v1/health）
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await ApiClient.I.ping();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? '已連線到後端（200）' : '後端不通')),
          );
          debugPrint('API_BASE_URL = ${ApiClient.I.baseUrl}');
        },
        child: const Icon(Icons.wifi_tethering),
      ),
    );
  }
}
