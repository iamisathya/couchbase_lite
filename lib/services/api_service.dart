import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:mindweave/models/post_model.dart';

class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const int maxPostId = 100;

  // Fetch a random post from JSONPlaceholder API
  static Future<PostModel> fetchRandomPost() async {
    try {
      // Generate random post ID (1-100)
      final randomId = Random().nextInt(maxPostId) + 1;
      final url = '$baseUrl/posts/$randomId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PostModel.fromJson(jsonData);
      } else {
        throw ApiException(
          'Failed to fetch post: HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  // Validate API connection (optional health check)
  static Future<bool> isApiAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/1'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get multiple random posts (for testing purposes)
  static Future<List<PostModel>> fetchMultipleRandomPosts(int count) async {
    final List<PostModel> posts = [];
    final List<Future<PostModel>> futures = [];

    for (int i = 0; i < count; i++) {
      futures.add(fetchRandomPost());
    }

    try {
      final results = await Future.wait(futures);
      posts.addAll(results);
      return posts;
    } catch (e) {
      throw ApiException('Failed to fetch multiple posts: ${e.toString()}', 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}