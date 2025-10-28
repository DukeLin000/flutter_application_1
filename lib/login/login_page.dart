// lib/login/login_page.dart
// Responsive Flutter Login/Register page (Web, iOS, Android)
// ------------------------------------------------------------------
// • 無第三方套件依賴（僅使用 Material）
// • 支援「登入 / 註冊」模式切換、顯示/隱藏密碼、條款勾選、記住我
// • 含「一鍵填入測試帳號」、三個社群登入按鈕（示意）、RWD 卡片佈局
// • onLogin 回呼在成功後觸發（模擬 API 呼叫）

import 'dart:async';
import 'package:flutter/material.dart';

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

  bool _showPwd = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {Color? color}) {
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
    _snack('已填入測試帳號，請點擊登入按鈕');
  }

  Future<void> _handleEmailAuth() async {
    // 基本驗證
    if (_emailCtrl.text.trim().isEmpty || _pwdCtrl.text.isEmpty) {
      _snack('請填寫所有欄位', color: Colors.red);
      return;
    }

    if (_mode == _AuthMode.register) {
      if (_pwdCtrl.text != _confirmCtrl.text) {
        _snack('密碼不一致', color: Colors.red);
        return;
      }
      if (!_agreeTerms) {
        _snack('請同意服務條款', color: Colors.red);
        return;
      }
      if (_pwdCtrl.text.length < 6) {
        _snack('密碼至少需要 6 個字元', color: Colors.red);
        return;
      }
    }

    setState(() => _isLoading = true);

    // 模擬 API 呼叫
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isLoading = false);

    _snack(_mode == _AuthMode.login ? '登入成功！' : '註冊成功！歡迎加入 WEAR');
    widget.onLogin();
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    _snack('正在透過 $provider 登入...');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isLoading = false);
    _snack('登入成功！');
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;

          // RWD：控制容器寬度與邊距
          final double cardMaxW = w >= 520 ? 520 : w * 0.95;
          final double verticalPad = w >= 768 ? 32 : 16;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF), Color(0xFFF3E8FF)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPad),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardMaxW),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LogoHeader(mode: _mode),
                        const SizedBox(height: 8),
                        _TipCard(
                          onFill: _isLoading ? null : _handleTestLogin,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 12),

                        // 社群登入
                        Column(
                          children: [
                            _SocialButton(
                              label: '使用 Google 繼續',
                              color: Colors.black87,
                              icon: Icons.g_mobiledata, // 簡化示意
                              onPressed: _isLoading ? null : () => _handleSocialLogin('Google'),
                            ),
                            const SizedBox(height: 10),
                            _SocialButton(
                              label: '使用 Facebook 繼續',
                              color: const Color(0xFF1877F2),
                              icon: Icons.facebook,
                              onPressed: _isLoading ? null : () => _handleSocialLogin('Facebook'),
                            ),
                            const SizedBox(height: 10),
                            _SocialButton(
                              label: '使用 Apple 繼續',
                              color: Colors.black,
                              icon: Icons.apple,
                              onPressed: _isLoading ? null : () => _handleSocialLogin('Apple'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        _Separator(text: '或使用信箱'),
                        const SizedBox(height: 16),

                        // 信箱登入/註冊表單
                        _EmailForm(
                          mode: _mode,
                          isLoading: _isLoading,
                          emailCtrl: _emailCtrl,
                          pwdCtrl: _pwdCtrl,
                          confirmCtrl: _confirmCtrl,
                          showPwd: _showPwd,
                          onTogglePwd: () => setState(() => _showPwd = !_showPwd),
                          agreeTerms: _agreeTerms,
                          onAgreeTermsChanged: (v) => setState(() => _agreeTerms = v ?? false),
                          rememberMe: _rememberMe,
                          onRememberChanged: (v) => setState(() => _rememberMe = v ?? false),
                          onSubmit: _isLoading ? null : _handleEmailAuth,
                        ),

                        const SizedBox(height: 12),

                        // 切換 登入/註冊
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _mode == _AuthMode.login ? '還沒有帳號？' : '已經有帳號了？',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() {
                                          _mode = _mode == _AuthMode.login
                                              ? _AuthMode.register
                                              : _AuthMode.login;
                                        }),
                                child: Text(
                                  _mode == _AuthMode.login ? '立即註冊' : '返回登入',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        // 底部說明
                        _BottomNote(),
                      ],
                    ),
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

class _LogoHeader extends StatelessWidget {
  final _AuthMode mode;
  const _LogoHeader({required this.mode});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall;
    final desc = mode == _AuthMode.login ? '歡迎回來！' : '加入我們的穿搭社群';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('W', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Text('WEAR', style: titleStyle),
        const SizedBox(height: 6),
        Text(desc, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final VoidCallback? onFill;
  final bool isLoading;
  const _TipCard({required this.onFill, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFFFFF8E1), // 近似 amber-50
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFFDE68A))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('💡', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('快速測試', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF78350F))),
                  const SizedBox(height: 2),
                  const Text('使用測試帳號快速體驗 WEAR 所有功能', style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                  const SizedBox(height: 8),
                  const Text('帳號：demo@wear.com', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                  const Text('密碼：demo123', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onFill,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFFCD34D)),
                        foregroundColor: const Color(0xFF78350F),
                      ),
                      child: const Text('一鍵填入測試帳號'),
                    ),
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

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: color),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  final String text;
  const _Separator({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _EmailForm extends StatelessWidget {
  final _AuthMode mode;
  final bool isLoading;
  final TextEditingController emailCtrl;
  final TextEditingController pwdCtrl;
  final TextEditingController confirmCtrl;
  final bool showPwd;
  final VoidCallback onTogglePwd;
  final bool agreeTerms;
  final ValueChanged<bool?> onAgreeTermsChanged;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberChanged;
  final Future<void> Function()? onSubmit;

  const _EmailForm({
    required this.mode,
    required this.isLoading,
    required this.emailCtrl,
    required this.pwdCtrl,
    required this.confirmCtrl,
    required this.showPwd,
    required this.onTogglePwd,
    required this.agreeTerms,
    required this.onAgreeTermsChanged,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        Text('電子信箱', style: labelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: emailCtrl,
          enabled: !isLoading,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.mail_outline),
            hintText: 'your@email.com',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Password
        Text('密碼', style: labelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: pwdCtrl,
          enabled: !isLoading,
          obscureText: !showPwd,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            hintText: mode == _AuthMode.register ? '至少 6 個字元' : '輸入密碼',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: isLoading ? null : onTogglePwd,
              icon: Icon(showPwd ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        ),

        if (mode == _AuthMode.register) ...[
          const SizedBox(height: 12),
          Text('確認密碼', style: labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: confirmCtrl,
            enabled: !isLoading,
            obscureText: !showPwd,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
              hintText: '再次輸入密碼',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: agreeTerms, onChanged: isLoading ? null : onAgreeTermsChanged),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    children: const [
                      TextSpan(text: '我同意 '),
                      TextSpan(text: '服務條款', style: TextStyle(color: Colors.blue)),
                      TextSpan(text: ' 和 '),
                      TextSpan(text: '隱私政策', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Checkbox(value: rememberMe, onChanged: isLoading ? null : onRememberChanged),
                const SizedBox(width: 4),
                Text('記住我', style: Theme.of(context).textTheme.bodySmall),
              ]),
              TextButton(onPressed: isLoading ? null : () {}, child: const Text('忘記密碼？')),
            ],
          ),
        ],

        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Text('處理中...'),
                    ],
                  )
                : Text(mode == _AuthMode.login ? '登入' : '建立帳號'),
          ),
        ),
      ],
    );
  }
}

class _BottomNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.auto_awesome, size: 14),
            SizedBox(width: 4),
            Text('AI 智能穿搭建議', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '加入 WEAR，探索個人風格，與社群分享你的穿搭靈感',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        )
      ],
    );
  }
}
