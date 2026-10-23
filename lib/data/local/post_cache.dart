import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../models/user.dart';

/// Посты из кэша + когда они были сохранены.
class CachedPosts {
  final List<Post> posts;
  final DateTime savedAt;

  const CachedPosts(this.posts, this.savedAt);
}

/// Простой локальный кэш на SharedPreferences (данные хранятся как JSON-строки).
class PostCache {
  PostCache(this._prefs);

  final SharedPreferences _prefs;

  static const _usersKey = 'users';
  static const _localPostsKey = 'local_posts';

  // Для каждого фильтра свой кэш: posts_all_asc, posts_3_desc ...
  static String _postsKey(int? userId, bool ascending) =>
      'posts_${userId ?? 'all'}_${ascending ? 'asc' : 'desc'}';

  // ---------- Посты ----------

  CachedPosts? readPosts({int? userId, required bool ascending}) {
    final key = _postsKey(userId, ascending);
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final posts = (map['posts'] as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
      return CachedPosts(posts, DateTime.parse(map['savedAt'] as String));
    } catch (e) {
      // Кэш испорчен — не падаем, просто забываем его
      debugPrint('[Cache] повреждён $key: $e');
      _prefs.remove(key);
      return null;
    }
  }

  Future<void> savePosts(
    List<Post> posts, {
    int? userId,
    required bool ascending,
  }) {
    return _prefs.setString(
      _postsKey(userId, ascending),
      jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'posts': posts.map((p) => p.toJson()).toList(),
      }),
    );
  }

  // ---------- Авторы ----------

  List<User> readUsers() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Cache] повреждены users: $e');
      return [];
    }
  }

  Future<void> saveUsers(List<User> users) => _prefs.setString(
        _usersKey,
        jsonEncode(users.map((u) => u.toJson()).toList()),
      );

  // ---------- Посты, созданные в приложении ----------

  List<Post> readLocalPosts() {
    final raw = _prefs.getString(_localPostsKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Cache] повреждены local_posts: $e');
      return [];
    }
  }

  Future<void> saveLocalPosts(List<Post> posts) => _prefs.setString(
        _localPostsKey,
        jsonEncode(posts.map((p) => p.toJson()).toList()),
      );
}
