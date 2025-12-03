import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../api/api_client.dart';

// ---------------------------------------------------------------------------
// 1. S-FLOW 動畫相關設定與 Painter
// ---------------------------------------------------------------------------

/// 定義主題顏色的介面
class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color glow;
  final Color text;
  final List<Color> bgGradient;
  final List<Color> accentGradient;
  final List<Color> lineGradient;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.glow,
    required this.text,
    required this.bgGradient,
    required this.accentGradient,
    required this.lineGradient,
  });
}

final _goldTheme = ThemeColors(
  primary: const Color(0xFFFBBF24),
  secondary: const Color(0xFFFDE68A),
  glow: const Color.fromRGBO(251, 191, 36, 0.6),
  text: const Color(0xFFFEF3C7),
  bgGradient: [
    const Color(0xFF0F172A),
    const Color(0xFF1C1917),
    Colors.black,
  ],
  accentGradient: [const Color(0xFFF59E0B), const Color(0xFFFDE047)],
  lineGradient: [const Color(0xFFFBBF24), const Color(0xFFF59E0B), const Color(0xFFFFFBEB)],
);

final _purpleTheme = ThemeColors(
  primary: const Color(0xFFA78BFA),
  secondary: const Color(0xFFF0ABFC),
  glow: const Color.fromRGBO(167, 139, 250, 0.6),
  text: const Color(0xFFEDE9FE),
  bgGradient: [
    const Color(0xFF0F172A),
    const Color(0xFF020617),
    Colors.black,
  ],
  accentGradient: [const Color(0xFF7C3AED), const Color(0xFF818CF8)],
  lineGradient: [const Color(0xFFA78BFA), const Color(0xFF8B5CF6), const Color(0xFFC4B5FD)],
);

/// 繪製 S-FLOW 線條與粒子的核心 Painter
class SFlowPainter extends CustomPainter {
  final double drawProgress; // 0.0 ~ 1.0
  final double pulseValue;   // 0.0 ~ 1.0 (循環)
  final ThemeColors colors;
  final bool showParticles;

  SFlowPainter({
    required this.drawProgress,
    required this.pulseValue,
    required this.colors,
    required this.showParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 定義 S 形狀路徑 (模擬 SVG)
    final Path basePath = Path();
    final double scaleX = w / 200;
    final double scaleY = h / 300;

    basePath.moveTo(120 * scaleX, 40 * scaleY);
    basePath.cubicTo(
      40 * scaleX, 40 * scaleY, 
      40 * scaleX, 120 * scaleY, 
      100 * scaleX, 150 * scaleY
    );
    basePath.cubicTo(
      160 * scaleX, 180 * scaleY, 
      160 * scaleX, 260 * scaleY, 
      80 * scaleX, 260 * scaleY
    );

    // 繪製多層線條
    for (int i = 0; i < 6; i++) {
      final double offsetFactor = i * 2.0;
      final double scaleFactor = 1.0 - (i * 0.02);
      
      final Matrix4 matrix = Matrix4.identity()
        ..translate(w / 2, h / 2)
        ..scale(scaleFactor)
        ..translate(-w / 2 + offsetFactor, -h / 2);

      final Path transformedPath = basePath.transform(matrix.storage);

      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (i * 0.5)
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: colors.lineGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, h));

      // 呼吸光暈
      final double glowOpacity = (0.3 + 0.2 * math.sin(pulseValue * 2 * math.pi)).clamp(0.0, 1.0);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * glowOpacity + 2);

      // 動畫路徑擷取
      final PathMetric pMetric = transformedPath.computeMetrics().first;
      final double extractEnd = pMetric.length * drawProgress;
      final Path extractPath = pMetric.extractPath(0.0, extractEnd);

      paint.color = paint.color.withOpacity(0.6);
      canvas.drawPath(extractPath, paint);

      // 粒子特效 (僅紫色模式)
      if (showParticles && drawProgress > 0.8) {
        final double speedFactor = 1.0 + (lineIndex: i * 0.1).lineIndex; // Just using i directly below
        final double rawPos = (pulseValue * (1.0 + i * 0.1)) % 1.0; 
        final double distance = pMetric.length * rawPos;
        final Tangent? tangent = pMetric.getTangentForOffset(distance);
        
        if (tangent != null) {
          final Paint dotPaint = Paint()
            ..color = Colors.white.withOpacity(0.8)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
          canvas.drawCircle(tangent.position, 2.0 + (math.Random().nextDouble() * 1.5), dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SFlowPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 2. 登入頁面主體
// ---------------------------------------------------------------------------

enum _AuthMode { login, register }

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Auth Logic State
  _AuthMode _mode = _AuthMode.login;
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _showPwd = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String _backendMsg = '';
  final String _baseUrl = ApiClient.I.baseUrl;

  // Animation State
  bool _isPurple = true; // 主題切換
  bool _formVisible = false; // 控制表單顯示
  
  late AnimationController _logoAnimCtrl;
  late AnimationController _pulseAnimCtrl;
  late Animation<double> _drawProgress;

  ThemeColors get _currentTheme => _isPurple ? _purpleTheme : _goldTheme;

  @override
  void initState() {
    super.initState();
    // 1. 線條繪製動畫 (3秒)
    _logoAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _drawProgress = CurvedAnimation(parent: _logoAnimCtrl, curve: Curves.easeInOut);

    // 2. 呼吸循環動畫
    _pulseAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // 3. 啟動序列
    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _logoAnimCtrl.forward();
    
    // 2.2秒後顯示登入表單
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) setState(() => _formVisible = true);
  }

  @override
  void dispose() {
    _logoAnimCtrl.dispose();
    _pulseAnimCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color ?? _currentTheme.primary),
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
      final pre = await ApiClient.I.preflight(_baseUrl);
      if (!pre.ok) throw '無法連接後端 (${pre.detail})';

      Map<String, dynamic> response;
      if (_mode == _AuthMode.login) {
        response = await ApiClient.I.login(email, pwd);
      } else {
        response = await ApiClient.I.register(email, pwd, _nameCtrl.text.trim());
      }

      final token = response['accessToken'] as String?;
      if (token == null) throw '回應缺少 accessToken';

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

  @override
  Widget build(BuildContext context) {
    final colors = _currentTheme;

    return Scaffold(
      // 使用 AnimatedContainer 讓背景色平滑過渡
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.bgGradient,
          ),
        ),
        child: Stack(
          children: [
            // 1. 背景裝飾光暈
            _buildBackgroundGlow(colors),

            // 2. 主內容區域
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  // 手機/Card 外框樣式
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    constraints: const BoxConstraints(maxWidth: 400), // 限制最大寬度
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3), // 半透明黑底
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: colors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.glow.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 右上角主題切換按鈕
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: () => setState(() => _isPurple = !_isPurple),
                            icon: Icon(
                              _isPurple ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                              color: _isPurple ? Colors.yellowAccent : Colors.purpleAccent,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),

                        // Logo 動畫區
                        SizedBox(
                          height: 220,
                          width: 160,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_logoAnimCtrl, _pulseAnimCtrl]),
                            builder: (_, __) => CustomPaint(
                              painter: SFlowPainter(
                                drawProgress: _drawProgress.value,
                                pulseValue: _pulseAnimCtrl.value,
                                colors: colors,
                                showParticles: _isPurple,
                              ),
                            ),
                          ),
                        ),
                        
                        // 標題 S-FLOW
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: colors.accentGradient,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: const Text(
                            'S-FLOW',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '智流',
                          style: TextStyle(
                            fontSize: 16,
                            letterSpacing: 8,
                            color: colors.secondary.withOpacity(0.8),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 登入表單 (動畫顯示)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 800),
                          opacity: _formVisible ? 1.0 : 0.0,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 800),
                            offset: _formVisible ? Offset.zero : const Offset(0, 0.1),
                            curve: Curves.easeOutQuart,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _mode == _AuthMode.login ? 'WELCOME BACK' : 'CREATE ACCOUNT',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                if (_mode == _AuthMode.register)
                                  _buildGlassTextField(
                                    controller: _nameCtrl,
                                    hint: 'NICKNAME',
                                    icon: Icons.person_outline,
                                    colors: colors,
                                  ),
                                if (_mode == _AuthMode.register) const SizedBox(height: 16),

                                _buildGlassTextField(
                                  controller: _emailCtrl,
                                  hint: 'EMAIL',
                                  icon: Icons.email_outlined,
                                  colors: colors,
                                ),
                                const SizedBox(height: 16),
                                _buildGlassTextField(
                                  controller: _pwdCtrl,
                                  hint: 'PASSWORD',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  showPwd: _showPwd,
                                  onTogglePwd: () => setState(() => _showPwd = !_showPwd),
                                  colors: colors,
                                ),

                                if (_mode == _AuthMode.register) ...[
                                  const SizedBox(height: 16),
                                  _buildGlassTextField(
                                    controller: _confirmCtrl,
                                    hint: 'CONFIRM PASSWORD',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    showPwd: _showPwd,
                                    colors: colors,
                                  ),
                                  const SizedBox(height: 8),
                                  Theme(
                                    data: ThemeData.dark(), // 強制 Checkbox 使用深色主題
                                    child: CheckboxListTile(
                                      value: _agreeTerms,
                                      onChanged: (v) => setState(() => _agreeTerms = v!),
                                      title: Text('同意服務條款', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                      activeColor: colors.primary,
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity: ListTileControlAffinity.leading,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                if (_isLoading)
                                  Center(child: CircularProgressIndicator(color: colors.primary))
                                else
                                  _buildGradientButton(
                                    text: _mode == _AuthMode.login ? 'LOGIN' : 'REGISTER',
                                    colors: colors,
                                    onPressed: _handleEmailAuth,
                                  ),

                                if (!_isLoading) 
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Center(
                                      child: TextButton(
                                        onPressed: _handleTestLogin,
                                        child: Text(
                                          '填入測試帳號',
                                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),

                                if (_backendMsg.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(_backendMsg, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                                  ),

                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {}, // 暫無功能
                                      child: Text('Forgot Password?', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _mode = _mode == _AuthMode.login ? _AuthMode.register : _AuthMode.login;
                                        _backendMsg = '';
                                      }),
                                      child: Text(
                                        _mode == _AuthMode.login ? 'Create Account' : 'Back to Login',
                                        style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. UI 輔助 Widget
  // ---------------------------------------------------------------------------

  Widget _buildBackgroundGlow(ThemeColors colors) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isPurple ? Colors.purple : Colors.amber).withOpacity(0.15),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isPurple ? Colors.blue : Colors.orange).withOpacity(0.15),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ThemeColors colors,
    bool isPassword = false,
    bool showPwd = false,
    VoidCallback? onTogglePwd,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !showPwd,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: colors.secondary.withOpacity(0.7), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(showPwd ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                  onPressed: onTogglePwd,
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13, letterSpacing: 1),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required ThemeColors colors,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: colors.accentGradient),
        boxShadow: [
          BoxShadow(
            color: colors.accentGradient.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}