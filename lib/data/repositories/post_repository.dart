import '../../core/error/app_exception.dart';
import '../local/post_cache.dart';
import '../models/comment.dart';
import '../models/create_post_request.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../remote/post_api.dart';

/// Repository — единственная точка доступа к данным для UI.
/// Решает: откуда брать данные (сервер или кэш), обновляет кэш
/// и превращает любые ошибки в AppException.
class PostRepository {
  PostRepository(this._api, this._cache);

  final PostApi _api;
  final PostCache _cache;

  static const pageSize = 10;

  // ---------- Список постов ----------

  /// Что лежит в кэше для этого фильтра (может быть null)
  CachedPosts? getCachedPosts({int? userId, bool ascending = true}) =>
      _cache.readPosts(userId: userId, ascending: ascending);

  /// Загрузить страницу с сервера и обновить кэш.
  /// Страница 1 заменяет кэш, следующие дописываются в конец.
  Future<List<Post>> fetchPosts({
    required int page,
    int? userId,
    bool ascending = true,
  }) async {
    try {
      final posts = await _api.getPosts(
        page: page,
        limit: pageSize,
        userId: userId,
        order: ascending ? 'asc' : 'desc',
      );
      final previous = page == 1
          ? <Post>[]
          : (_cache.readPosts(userId: userId, ascending: ascending)?.posts ??
              <Post>[]);
      await _cache.savePosts(
        [...previous, ...posts],
        userId: userId,
        ascending: ascending,
      );
      return posts;
    } catch (e) {
      // При ошибке кэш НЕ трогаем — последний успешный результат сохраняется
      throw AppException.from(e);
    }
  }

  // ---------- Пост, комментарии, автор ----------

  Future<Post> getPost(int id) => _guard(() => _api.getPost(id));

  Future<List<Comment>> getComments(int postId) =>
      _guard(() => _api.getComments(postId));

  Future<List<Post>> getPostsByUser(int userId) =>
      _guard(() => _api.getPostsByUser(userId));

  Future<User> getUser(int id) => _guard(() => _api.getUser(id));

  /// Авторы: с сервера, а если сети нет — из кэша
  Future<List<User>> getUsers() async {
    try {
      final users = await _api.getUsers();
      await _cache.saveUsers(users);
      return users;
    } catch (e) {
      final cached = _cache.readUsers();
      if (cached.isNotEmpty) return cached;
      throw AppException.from(e);
    }
  }

  List<User> getCachedUsers() => _cache.readUsers();

  // ---------- Создание поста ----------

  /// Отправляет POST. JSONPlaceholder отвечает объектом с id = 101,
  /// но НЕ сохраняет его. Поэтому мы храним пост у себя с пометкой isLocal.
  Future<Post> createPost(CreatePostRequest request) async {
    final created = await _guard(() => _api.createPost(request));
    final local = created.copyWith(isLocal: true);
    await _cache.saveLocalPosts([local, ..._cache.readLocalPosts()]);
    return local;
  }

  List<Post> getLocalPosts() => _cache.readLocalPosts();

  // ---------- Фильтрация (чистые функции, удобно тестировать) ----------

  static List<Post> filterByTitle(List<Post> posts, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return posts;
    return posts.where((p) => p.title.toLowerCase().contains(q)).toList();
  }

  static List<Post> filterByAuthor(List<Post> posts, int? userId) {
    if (userId == null) return posts;
    return posts.where((p) => p.userId == userId).toList();
  }

  // Выполнить запрос и любую ошибку превратить в AppException
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
