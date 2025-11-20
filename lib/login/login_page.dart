// lib/login/login_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api_client.dart';

enum _AuthMode { login, register }

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  _AuthMode _mode = _AuthMode.login;
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // 新增：註冊需要暱稱

  bool _showPwd = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  String _backendMsg = '';
  final String _baseUrl = ApiClient.I.baseUrl;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _handleTestLogin() {
    setState(() {
      _emailCtrl.text = 'demo@wear.com';
      _pwdCtrl.text = 'demo123';
      _mode = _AuthMode.login;
    });
    _snack('已填入測試帳號');
  }

  // 核心：真實 API 串接邏輯
  Future<void> _handleEmailAuth() async {
    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    
    if (email.isEmpty || pwd.isEmpty) {
      _snack('請填寫所有欄位', color: Colors.red);
      return;
    }

    if (_mode == _AuthMode.register) {
      if (pwd != _confirmCtrl.text) {
        _snack('兩次密碼不一致', color: Colors.red);
        return;
      }
      if (_nameCtrl.text.trim().isEmpty) {
        _snack('請輸入暱稱', color: Colors.red);
        return;
      }
      if (!_agreeTerms) {
        _snack('請同意服務條款', color: Colors.red);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _backendMsg = '連線中...';
    });

    try {
      // 1. Preflight 檢查後端
      final pre = await ApiClient.I.preflight(_baseUrl);
      if (!pre.ok) throw '無法連接後端 (${pre.detail})';

      // 2. 呼叫登入或註冊 API
      Map<String, dynamic> response;
      if (_mode == _AuthMode.login) {
        response = await ApiClient.I.login(email, pwd);
      } else {
        response = await ApiClient.I.register(email, pwd, _nameCtrl.text.trim());
      }

      // 3. 取得 Token
      final token = response['accessToken'] as String?;
      if (token == null) throw '回應缺少 accessToken';

      // 4. 初始化 Client
      await ApiClient.I.boot(baseUrl: _baseUrl, token: token);
      
      _snack(_mode == _AuthMode.login ? '登入成功' : '註冊成功');
      widget.onLogin();

    } catch (e) {
      setState(() => _backendMsg = '錯誤: $e');
      _snack('操作失敗: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 社群登入暫時保留為 Demo，因為後端尚未實作 OAuth
  Future<void> _handleSocialLogin(String provider) async {
    _snack('目前僅支援 Email 登入 (後端尚未實作 OAuth)', color: Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    // UI 部分保持與你原本的一致，稍微調整欄位顯示
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final double cardMaxW = w >= 520 ? 520 : w * 0.95;
          
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF), Color(0xFFF3E8FF)],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.checkroom, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _mode == _AuthMode.login ? '歡迎回來' : '建立帳號',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),

                      if (_mode == _AuthMode.register)
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: '暱稱', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                        ),
                      if (_mode == _AuthMode.register) const SizedBox(height: 12),

                      TextField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pwdCtrl,
                        obscureText: !_showPwd,
                        decoration: InputDecoration(
                          labelText: '密碼',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_showPwd ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPwd = !_showPwd),
                          ),
                        ),
                      ),
                      
                      if (_mode == _AuthMode.register) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmCtrl,
                          obscureText: !_showPwd,
                          decoration: const InputDecoration(labelText: '確認密碼', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                        ),
                        CheckboxListTile(
                          value: _agreeTerms,
                          onChanged: (v) => setState(() => _agreeTerms = v!),
                          title: const Text('同意服務條款'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],

                      const SizedBox(height: 24),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        FilledButton(
                          onPressed: _handleEmailAuth,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: Text(_mode == _AuthMode.login ? '登入' : '註冊'),
                        ),

                      if (!_isLoading) 
                        TextButton(onPressed: _handleTestLogin, child: const Text('填入測試帳號')),

                      if (_backendMsg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_backendMsg, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                        ),

                      const Divider(height: 32),
                      TextButton(
                        onPressed: () => setState(() {
                          _mode = _mode == _AuthMode.login ? _AuthMode.register : _AuthMode.login;
                          _backendMsg = '';
                        }),
                        child: Text(_mode == _AuthMode.login ? '還沒有帳號？立即註冊' : '已有帳號？返回登入'),
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
}