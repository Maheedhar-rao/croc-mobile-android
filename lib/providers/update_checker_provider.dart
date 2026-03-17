import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';

const _currentVersion = '1.3.0';
const _repoOwner = 'Maheedhar-rao';
const _repoName = 'croc-mobile-android';

bool _updateDialogShown = false;

final updateCheckerProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest'),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final latestTag = (data['tag_name'] ?? '').toString().replaceAll('v', '');

    if (latestTag.isEmpty || latestTag == _currentVersion) return null;

    // Find APK asset
    final assets = data['assets'] as List? ?? [];
    String? apkUrl;
    for (final asset in assets) {
      final name = (asset['name'] ?? '').toString().toLowerCase();
      if (name.endsWith('.apk')) {
        apkUrl = asset['browser_download_url'] as String?;
        break;
      }
    }

    if (apkUrl == null) return null;

    debugPrint('[update] New version available: $latestTag (current: $_currentVersion)');

    return {
      'version': latestTag,
      'url': apkUrl,
      'notes': data['body'] ?? '',
    };
  } catch (e) {
    debugPrint('[update] Check failed: $e');
    return null;
  }
});

void showUpdateDialog(BuildContext context, Map<String, dynamic> update) {
  if (_updateDialogShown) return;
  _updateDialogShown = true;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.system_update_rounded, size: 22, color: C.primary),
          SizedBox(width: 10),
          Text('Update Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version ${update['version']} is available.',
              style: const TextStyle(color: C.textSecondary)),
          if ((update['notes'] as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(update['notes'],
                style: const TextStyle(fontSize: 13, color: C.textTertiary),
                maxLines: 5,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            launchUrl(Uri.parse(update['url']), mode: LaunchMode.externalApplication);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: C.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Update'),
        ),
      ],
    ),
  );
}
