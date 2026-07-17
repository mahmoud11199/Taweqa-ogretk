class ReleaseInfo {
  final String version;
  final String? apkUrl;
  final String? iosUrl;
  final String? webUrl;
  final String? releaseNotes;

  ReleaseInfo({
    required this.version,
    this.apkUrl,
    this.iosUrl,
    this.webUrl,
    this.releaseNotes,
  });

  factory ReleaseInfo.fromGitHubApi(Map<String, dynamic> json) {
    String? apkUrl;
    String? iosUrl;
    String? webUrl;

    final assets = json['assets'] as List<dynamic>? ?? [];
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      final url = asset['browser_download_url'] as String?;
      if (url != null) {
        if (name.endsWith('.apk')) apkUrl = url;
        if (name.endsWith('.ipa')) iosUrl = url;
        if (name.contains('web')) webUrl = url;
      }
    }

    return ReleaseInfo(
      version: json['tag_name'] as String? ?? '1.0.0',
      apkUrl: apkUrl,
      iosUrl: iosUrl,
      webUrl: webUrl,
      releaseNotes: json['body'] as String?,
    );
  }
}
