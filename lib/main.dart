import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kDebugMode
// ✅ LoginPage
import 'theme/app_theme.dart';

// ✅ 共用資料模型：務必存在 lib/models/user_profile.dart，且全專案只保留這一份
import 'models/user_profile.dart';

// ✅ LoginPage
import 'login/login_page.dart';

// 既有頁面
import 'page/onboarding_page.dart' ;
import 'page/home_page.dart';
import 'page/community_page.dart';
import 'page/wardrobe_page.dart';
import 'page/ai_page.dart';
import 'page/profile_page.dart';
import 'page/profilepage/capsule_page.dart';
import 'page/profilepage/shop_page.dart';
import 'page/profilepage/settings_page.dart';

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
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //   useMaterial3: true,
      // ),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // 或 ThemeMode.dark / light,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      // 先進 Login，再導到 Onboarding → RootShell
      home: LoginPage(
        onLogin: () {
          final nav = navigatorKey.currentState;
          if (nav == null) return;

          nav.pushReplacement(
            MaterialPageRoute(
              builder: (_) => OnboardingPage(
                onComplete: (profile) async {
                  final n = navigatorKey.currentState;
                  if (n == null) return;

                  // 顯示 Loading
                  showDialog(
                    context: n.context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final saved = await ApiClient.I.saveProfile(profile.toJson());
                    if (kDebugMode) {
                      debugPrint('後端已接收：$saved');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(n.context).showSnackBar(
                      SnackBar(content: Text('無法連線後端：$e')),
                    );
                  } finally {
                    // 關閉 Loading
                    Navigator.of(n.context).pop();
                  }

                  // 進入主殼，並清空返回堆疊
                  n.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const _RootShell()),
                    (route) => false,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// App 殼：底部導覽（Home / Community / Wardrobe / AI / Profile）
class _RootShell extends StatefulWidget {
  const _RootShell({super.key});

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _index = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  // 本地暫存的使用者設定（示例）
  late UserProfile _userProfile;

  @override
  void initState() {
    super.initState();
    // 先給預設/示例資料；若你已有後端資料，可在這裡替換為 API 取回的內容。
    _userProfile = UserProfile(
      height: 175,
      weight: 70,
      shoulderWidth: 45,
      waistline: 80,
      fitPreference: 'regular', // 'slim' | 'regular' | 'oversized'
      colorBlacklist: const [],
      hasMotorcycle: false,
      commuteMethod: 'public', // 'public' | 'car' | 'walk'
      styleWeights: const {'street': 34, 'outdoor': 33, 'office': 33},
      gender: 'male', // 'male' | 'female' | 'other'
    );
  }

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

  // 開啟設定頁（SettingsPage）
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          userProfile: _userProfile,
          onUpdateProfile: (updated) {
            setState(() => _userProfile = updated);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('個人設定已儲存')),
            );
            // TODO: 若需同步到後端，可在此呼叫 ApiClient.I.saveProfile(updated.toJson())
          },
          onLogout: () {
            // 回到 Login（並清空堆疊）
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => LoginPage(
                  onLogin: () {
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const _RootShell()),
                      (route) => false,
                    );
                  },
                ),
              ),
              (route) => false,
            );
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
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
            case 'settings': // 從個人中心前往「設定」
              _openSettings();
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
