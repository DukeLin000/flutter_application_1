// 在非 Web 環境使用 dart:io，Web 改用空實作
export 'platform_io.dart' if (dart.library.html) 'platform_web.dart';
