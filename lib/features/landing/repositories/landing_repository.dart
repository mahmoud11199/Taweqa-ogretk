import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../models/release_info.dart';

class LandingRepository {
  Future<ReleaseInfo?> fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.gitHubReleasesApi),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          return ReleaseInfo.fromGitHubApi(data[0] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }
}
