import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kDebugMode

// Theme
import 'theme/app_theme.dart';
import 'theme/s_flow_design.dart'; // ✅ 引入 S-FLOW 設計系統

// Models
import 'models/user_profile.dart';

// Login & Onboarding
import 'login/login_page.dart';
import 'page/onboarding_page.dart' hide UserProfile;

// Pages (Main Tabs)
import 'page/home_page.dart';        // React: Discover
import 'page/community_page.dart';   // React: Home
import 'page/wardrobe_page.dart';    // React: Wardrobe
import 'page/ai_page.dart';          // React: AI
import 'page/profile_page.dart';     // React: Profile

// Pages (Sub Pages)
import 'page/profilepage/capsule_page.dart';
import 'page/profilepage/shop_page.dart';
import 'page/profilepage/settings_page.dart';
import 'page/profilepage/notification_page.dart';

// API client
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
      title: 'S-FLOW App',
      // ✅ 強制使用深色主題以配合 S-FLOW 風格
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      
      // 初始流程：Login -> Onboarding -> App
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

                  // Loading
                  showDialog(
                    context: n.context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await ApiClient.I.saveProfile(profile.toJson());
                  } catch (e) {
                    if (n.mounted) {
                      ScaffoldMessenger.of(n.context).showSnackBar(
                        SnackBar(content: Text('無法連線後端：$e')),
                      );
                    }
                  } finally {
                    if (n.canPop()) Navigator.of(n.context).pop();
                  }

                  // 進入 App Shell
                  n.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => _AppShell(userProfile: profile),
                    ),
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

/// App 殼層：負責管理全域狀態 (Tab, Theme) 與主要導航結構
class _AppShell extends StatefulWidget {
  final UserProfile userProfile;
  const _AppShell({required this.userProfile});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  // 導航狀態
  String _activeTab = 'home'; 
  String? _subPage;
  String _settingsTab = 'profile';
  
  // 資料狀態
  late UserProfile _userProfile;
  
  // 頁面緩存
  final PageStorageBucket _bucket = PageStorageBucket();

  // ✅ S-FLOW Theme State (全域主題控制)
  bool _isPurple = true;
  SFlowColors get _currentColors => _isPurple ? SFlowThemes.purple : SFlowThemes.gold;

  @override
  void initState() {
    super.initState();
    _userProfile = widget.userProfile;
  }

  // --- Actions ---

  void _handleAddItems() {
    setState(() {
      _activeTab = 'wardrobe';
      _subPage = null;
    });
  }

  void _handleLogout() {
    ApiClient.I.logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          onLogin: () {
            main(); // 重啟
          },
        ),
      ),
      (route) => false,
    );
  }

  void _handleUpdateProfile(UserProfile updated) {
    setState(() => _userProfile = updated);
  }

  void _handleProfileNavigate(String page, [String? tab]) {
    setState(() {
      if (page == "capsule") {
        _subPage = "capsule";
      } else if (page == "shop") {
        _subPage = "shop";
      } else if (page == "saved") {
        _subPage = "saved";
      } else if (page == "shared") {
        _subPage = "shared";
      } else if (page == "settings") {
        _settingsTab = tab ?? 'profile';
        _subPage = "settings";
      } else if (page == "notificationSettings") {
        _settingsTab = 'notifications';
        _subPage = "settings";
      } else if (page == "notifications") {
        _activeTab = "notifications";
        _subPage = null; 
      }
    });
  }

  void _handleBackToProfile() {
    setState(() => _subPage = null);
  }

  // 切換主題 (金/紫)
  void _toggleTheme() {
    setState(() => _isPurple = !_isPurple);
  }

  // Tab Index Helpers
  int _getTabIndex() {
    switch (_activeTab) {
      case 'home': return 0;
      case 'discover': return 1;
      case 'wardrobe': return 2;
      case 'ai': return 3;
      case 'notifications': return 4;
      case 'profile': return 5;
      default: return 0;
    }
  }

  void _setTabIndex(int index) {
    String newTab;
    switch (index) {
      case 0: newTab = 'home'; break;
      case 1: newTab = 'discover'; break;
      case 2: newTab = 'wardrobe'; break;
      case 3: newTab = 'ai'; break;
      case 5: newTab = 'profile'; break;
      default: newTab = 'home';
    }
    setState(() {
      _activeTab = newTab;
      _subPage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    Widget content;

    if (_subPage != null) {
      // --- Sub Pages ---
      switch (_subPage) {
        case 'capsule':
          content = const CapsulePage(); 
          break;
        case 'shop':
          content = ShopPage(onBack: _handleBackToProfile);
          break;
        case 'saved':
          content = _buildPlaceholder('Saved Page');
          break;
        case 'shared':
          content = _buildPlaceholder('Shared Page');
          break;
        case 'settings':
          content = SettingsPage(
            userProfile: _userProfile,
            onUpdateProfile: _handleUpdateProfile,
            onLogout: _handleLogout,
            onBack: _handleBackToProfile,
          );
          break;
        default:
          content = _buildPlaceholder('Unknown SubPage');
      }
    } 
    else {
      // --- Main Tabs ---
      // 注意：這裡將 _currentColors 傳入 HomePage 讓其可使用
      switch (_activeTab) {
        case 'home':
          content = const CommunityPage(key: PageStorageKey('community'));
          break;
        case 'discover':
          content = HomePage(
            key: const PageStorageKey('home'),
            hasItems: true,
            onAddItems: _handleAddItems,
            // 傳遞主題控制給首頁 (如果 HomePage 有定義這些參數)
            // onThemeToggle: _toggleTheme, 
            // currentColors: _currentColors,
          );
          break;
        case 'wardrobe':
          content = const WardrobePage(key: PageStorageKey('wardrobe'));
          break;
        case 'ai':
          content = const AIPage(key: PageStorageKey('ai'));
          break;
        case 'notifications':
          content = NotificationPage(
            onBack: () => setState(() => _activeTab = 'home'),
            onNavigate: (tab) {
               if (tab == 'shop') setState(() => _subPage = 'shop');
            },
          );
          break;
        case 'profile':
          content = ProfilePage(
            key: const PageStorageKey('profile'),
            onNavigate: _handleProfileNavigate,
          );
          break;
        default:
          content = const CommunityPage();
      }
    }

    final body = PageStorage(bucket: _bucket, child: content);

    // ✅ 核心：使用 SFlowBackground 包覆整個 Scaffold，並設為透明
    return SFlowBackground(
      colors: _currentColors,
      child: Scaffold(
        backgroundColor: Colors.transparent, // ★ 重要：讓背景透出來
        body: isDesktop
          ? Row(
              children: [
                // 桌面版側欄 (NavigationRail)
                NavigationRail(
                  backgroundColor: Colors.black.withOpacity(0.6), // 半透明
                  indicatorColor: _currentColors.primary.withOpacity(0.2),
                  selectedIndex: _getTabIndex() > 4 ? 4 : _getTabIndex(),
                  onDestinationSelected: (i) {
                    final mappedIndex = i == 4 ? 5 : i;
                    _setTabIndex(mappedIndex);
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Icon(Icons.checkroom, size: 32, color: _currentColors.primary),
                  ),
                  unselectedIconTheme: IconThemeData(color: _currentColors.textDim),
                  selectedIconTheme: IconThemeData(color: _currentColors.primary),
                  selectedLabelTextStyle: TextStyle(color: _currentColors.primary),
                  unselectedLabelTextStyle: TextStyle(color: _currentColors.textDim),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('社群')),
                    NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('每日')),
                    NavigationRailDestination(icon: Icon(Icons.checkroom_outlined), selectedIcon: Icon(Icons.checkroom), label: Text('衣櫃')),
                    NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: Text('AI')),
                    NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('個人')),
                  ],
                ),
                VerticalDivider(thickness: 1, width: 1, color: _currentColors.glassBorder),
                Expanded(child: body),
              ],
            )
          : body,
        
        // 行動版底部導航 (NavigationBar)
        bottomNavigationBar: isDesktop 
          ? null 
          : NavigationBar(
              backgroundColor: Colors.black.withOpacity(0.8), // 玻璃感深色底
              indicatorColor: _currentColors.primary.withOpacity(0.2),
              selectedIndex: _getTabIndex() > 4 ? 4 : _getTabIndex(),
              onDestinationSelected: (i) {
                 final mappedIndex = i == 4 ? 5 : i;
                 _setTabIndex(mappedIndex);
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.people_outline, color: _currentColors.textDim), 
                  selectedIcon: Icon(Icons.people, color: _currentColors.primary), 
                  label: '社群'
                ),
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: _currentColors.textDim), 
                  selectedIcon: Icon(Icons.home, color: _currentColors.primary), 
                  label: '每日'
                ),
                NavigationDestination(
                  icon: Icon(Icons.checkroom_outlined, color: _currentColors.textDim), 
                  selectedIcon: Icon(Icons.checkroom, color: _currentColors.primary), 
                  label: '衣櫃'
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined, color: _currentColors.textDim), 
                  selectedIcon: Icon(Icons.auto_awesome, color: _currentColors.primary), 
                  label: 'AI'
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline, color: _currentColors.textDim), 
                  selectedIcon: Icon(Icons.person, color: _currentColors.primary), 
                  label: '個人'
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: _currentColors.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _currentColors.text),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _handleBackToProfile),
      ),
      body: Center(child: Text('功能開發中', style: TextStyle(color: _currentColors.textDim))),
    );
  }
}