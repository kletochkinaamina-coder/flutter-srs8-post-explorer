import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import 'posts_state.dart';

/// Логика экрана списка: загрузка, пагинация, кэш, фильтры.
class PostsCubit extends Cubit<PostsState> {
  PostsCubit(this._repository) : super(const PostsState());

  final PostRepository _repository;

  // Номер актуального запроса. Если пользователь сменил фильтр,
  // ответы старых запросов игнорируются — результаты не смешиваются.
  int _requestId = 0;

  /// Авторы для фильтра и формы
  Future<void> loadUsers() async {
    emit(state.copyWith(users: _repository.getCachedUsers()));
    try {
      final users = await _repository.getUsers();
      emit(state.copyWith(users: users));
    } on AppException {
      // Авторы не критичны: список постов работает и без них
    }
  }

  /// Первая страница: сначала кэш, затем свежие данные с сервера.
  /// Также вызывается при pull-to-refresh и смене фильтра.
  Future<void> loadFirstPage() async {
    final requestId = ++_requestId;
    final cached = _repository.getCachedPosts(
      userId: state.userId,
      ascending: state.ascending,
    );
    final hasCache = cached != null && cached.posts.isNotEmpty;

    emit(state.copyWith(
      status: hasCache ? PostsStatus.cached : PostsStatus.loading,
      posts: hasCache ? cached.posts : const [],
      cachedAt: hasCache ? cached.savedAt : null,
      localPosts: _repository.getLocalPosts(),
      page: 0, // пока сервер не ответил, подгрузку страниц не разрешаем
      hasMore: true,
      isLoadingMore: false,
      loadMoreError: null,
      errorMessage: null,
    ));

    try {
      final posts = await _repository.fetchPosts(
        page: 1,
        userId: state.userId,
        ascending: state.ascending,
      );
      if (requestId != _requestId) return; // устаревший ответ
      emit(state.copyWith(
        status: posts.isEmpty ? PostsStatus.empty : PostsStatus.success,
        posts: posts,
        page: 1,
        hasMore: posts.length == PostRepository.pageSize,
        cachedAt: null,
      ));
    } on AppException catch (e) {
      if (requestId != _requestId) return;
      // Есть что показать — оставляем кэш и сообщаем об ошибке
      emit(state.copyWith(
        status: state.posts.isNotEmpty ? PostsStatus.cached : PostsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  /// Следующая страница при прокрутке
  Future<void> loadNextPage() async {
    // Защита от повторной загрузки одной и той же страницы
    if (state.isLoadingMore || !state.hasMore || state.page == 0) return;

    final requestId = _requestId;
    final nextPage = state.page + 1;
    emit(state.copyWith(isLoadingMore: true, loadMoreError: null));

    try {
      final posts = await _repository.fetchPosts(
        page: nextPage,
        userId: state.userId,
        ascending: state.ascending,
      );
      if (requestId != _requestId) return;
      emit(state.copyWith(
        posts: [...state.posts, ...posts],
        page: nextPage,
        hasMore: posts.length == PostRepository.pageSize,
        isLoadingMore: false,
      ));
    } on AppException catch (e) {
      if (requestId != _requestId) return;
      emit(state.copyWith(isLoadingMore: false, loadMoreError: e.message));
    }
  }

  // ---------- Фильтры ----------

  /// null — все посты, число — посты выбранного автора
  void selectAuthor(int? userId) {
    if (userId == state.userId) return;
    emit(state.copyWith(userId: userId));
    loadFirstPage(); // страницы сбрасываются
  }

  void toggleSort() {
    emit(state.copyWith(ascending: !state.ascending));
    loadFirstPage();
  }

  /// Поиск — локально, по уже загруженным постам
  void search(String query) => emit(state.copyWith(query: query));

  void resetFilters() {
    final needReload = state.userId != null || !state.ascending;
    emit(state.copyWith(userId: null, ascending: true, query: ''));
    if (needReload) loadFirstPage();
  }

  /// Пост, созданный на экране «Новый пост»
  void addLocalPost(Post post) {
    emit(state.copyWith(localPosts: _repository.getLocalPosts()));
  }
}
