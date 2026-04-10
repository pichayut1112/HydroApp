import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// ── ตั้งค่า repo ของคุณตรงนี้ ──────────────────────────────────────────────
const _kOwner = 'pichayut1112';
const _kRepo = 'HydroApp';
// ────────────────────────────────────────────────────────────────────────────

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService._();
  UpdateService._();

  /// เช็คว่ามีเวอร์ชันใหม่ไหม คืน UpdateInfo ถ้ามี, null ถ้าไม่มี
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = _parseVersion(info.version);

      final uri = Uri.parse('https://api.github.com/repos/$_kOwner/$_kRepo/releases/latest');
      final res = await http
          .get(uri, headers: {'Accept': 'application/vnd.github.v3+json'}).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String).replaceFirst('v', '');
      final latest = _parseVersion(tag);

      if (!_isNewer(latest, current)) return null;

      // หา APK asset
      final assets = (json['assets'] as List).cast<Map<String, dynamic>>();
      final apk = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => {'browser_download_url': json['html_url']},
      );

      return UpdateInfo(
        latestVersion: tag,
        downloadUrl: apk['browser_download_url'] as String,
        releaseNotes: (json['body'] as String? ?? '').trim(),
      );
    } catch (e) {
      debugPrint('[Hydro][Update] Check failed: $e');
      return null;
    }
  }

  Future<void> openDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<int> _parseVersion(String v) {
    return v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  bool _isNewer(List<int> latest, List<int> current) {
    for (var i = 0; i < 3; i++) {
      final l = i < latest.length ? latest[i] : 0;
      final c = i < current.length ? current[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
