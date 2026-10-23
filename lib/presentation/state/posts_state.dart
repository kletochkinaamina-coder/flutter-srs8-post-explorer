import 'package:equatable/equatable.dart';

import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

/// Состояние основного списка.
/// loading — первая загрузка, success — данные с сервера,
/// cached — показан кэш (идёт обновление или сервер недоступен),
/// error — ошибка и показать нечего, empty — сервер вернул пустой список.
enum PostsStatus { initial, loading, success, cached, error, empty }

class PostsState extends Equatable {
  final PostsStatus status;
  final List<Post> posts; // посты с сервера (или из кэша)
  final List<Post> localPosts; // созданные в приложении
  final List<User> users;

  // Пагинация — отдельно от status, потому что подгрузка страницы
  // идёт независимо от первой загрузки
  final int page; // последняя загруженная страница (0 — ещё ничего)
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;

  final String? errorMessage;
  final DateTime? cachedAt;

  // Фильтры
  final int? userId; // null — все авторы
  final bool ascending; // сортировка по ID
  final String query; // поиск по заголовку среди загруженных

  const PostsState({
    this.status = PostsStatus.initial,
    this.posts = const [],
    this.localPosts = const [],
    this.users = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.errorMessage,
    this.cachedAt,
    this.userId,
    this.ascending = true,
    this.query = '',
  });

  /// То, что видно на экране: локальные посты + загруженные, с учётом поиска
  List<Post> get visiblePosts {
    final local = PostRepository.filterByAuthor(localPosts, userId);
    return PostRepository.filterByTitle([...local, ...posts], query);
  }

  String authorName(int id) {
    for (final u in users) {
      if (u.id == id) return u.name;
    }
    return 'Автор #$id';
  }

  // Маркер «не менять» для полей, которые могут стать null
  static const _keep = Object();

  PostsState copyWith({
    PostsStatus? status,
    List<Post>? posts,
    List<Post>? localPosts,
    List<User>? users,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError = _keep,
    Object? errorMessage = _keep,
    Object? cachedAt = _keep,
    Object? userId = _keep,
    bool? ascending,
    String? query,
  }) {
    return PostsState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      localPosts: localPosts ?? this.localPosts,
      users: users ?? this.users,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError == _keep
          ? this.loadMoreError
          : loadMoreError as String?,
      errorMessage:
          errorMessage == _keep ? this.errorMessage : errorMessage as String?,
      cachedAt: cachedAt == _keep ? this.cachedAt : cachedAt as DateTime?,
      userId: userId == _keep ? this.userId : userId as int?,
      ascending: ascending ?? this.ascending,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [
        status,
        posts,
        localPosts,
        users,
        page,
        hasMore,
        isLoadingMore,
        loadMoreError,
        errorMessage,
        cachedAt,
        userId,
        ascending,
        query,
      ];
}
