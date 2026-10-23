import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:srs8_app/core/error/app_exception.dart';
import 'package:srs8_app/data/local/post_cache.dart';
import 'package:srs8_app/data/models/post.dart';
import 'package:srs8_app/data/models/user.dart';
import 'package:srs8_app/data/repositories/post_repository.dart';
import 'package:srs8_app/presentation/state/create_post_cubit.dart';
import 'package:srs8_app/presentation/state/posts_cubit.dart';
import 'package:srs8_app/presentation/state/posts_state.dart';

/// Поддельный репозиторий: считает вызовы и отвечает тем, что мы скажем.
class FakeRepository extends Fake implements PostRepository {
  final calls = <String>[];
  Future<List<Post>> Function(int page, int? userId)? onFetch;
  CachedPosts? cache;

  @override
  CachedPosts? getCachedPosts({int? userId, bool ascending = true}) => cache;

  @override
  Future<List<Post>> fetchPosts({required int page, int? userId, bool ascending = true}) {
    calls.add('page=$page user=$userId');
    return onFetch!(page, userId);
  }

  @override
  List<Post> getLocalPosts() => [];

  @override
  List<User> getCachedUsers() => [];
}

List<Post> makePosts(int from, int count, {int userId = 1}) => [
      for (var i = from; i < from + count; i++)
        Post(id: i, userId: userId, title: 'Post $i', body: ''),
    ];

void main() {
  late FakeRepository repo;
  late PostsCubit cubit;

  setUp(() {
    repo = FakeRepository();
    cubit = PostsCubit(repo);
  });

  tearDown(() => cubit.close());

  test('6. Защита от дублирующейся загрузки одной страницы', () async {
    repo.onFetch = (page, _) async => makePosts(1, 10);
    await cubit.loadFirstPage();

    // Страница 2 «висит», пока мы не ответим
    final completer = Completer<List<Post>>();
    repo.onFetch = (page, _) => completer.future;

    // Пользователь быстро прокручивает — loadNextPage вызывается 3 раза
    final f1 = cubit.loadNextPage();
    final f2 = cubit.loadNextPage();
    final f3 = cubit.loadNextPage();

    completer.complete(makePosts(11, 10));
    await Future.wait([f1, f2, f3]);

    expect(repo.calls.where((c) => c.startsWith('page=2')).length, 1);
    expect(cubit.state.posts.length, 20);
    expect(cubit.state.posts.map((p) => p.id).toSet().length, 20); // нет дублей
  });

  test('Смена фильтра сбрасывает страницы, старые результаты не смешиваются', () async {
    repo.onFetch = (page, userId) async =>
        makePosts(page * 100, 10, userId: userId ?? 1);
    await cubit.loadFirstPage();
    await cubit.loadNextPage(); // 20 постов автора «все»

    cubit.selectAuthor(3);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.page, 1);
    expect(cubit.state.posts.length, 10);
    expect(cubit.state.posts.every((p) => p.userId == 3), true);
  });

  test('Нет интернета, но есть кэш -> состояние cached, данные остаются', () async {
    repo.cache = CachedPosts(makePosts(1, 5), DateTime(2026, 1, 1));
    repo.onFetch = (_, _) async => throw const AppException(
        AppErrorType.noConnection, 'Нет подключения к интернету.');

    await cubit.loadFirstPage();

    expect(cubit.state.status, PostsStatus.cached);
    expect(cubit.state.posts.length, 5);
    expect(cubit.state.errorMessage, 'Нет подключения к интернету.');
  });

  test('Ошибка следующей страницы не ломает список и даёт повторить', () async {
    repo.onFetch = (page, _) async => makePosts(1, 10);
    await cubit.loadFirstPage();

    repo.onFetch = (_, _) async =>
        throw const AppException(AppErrorType.timeout, 'Сервер долго не отвечает.');
    await cubit.loadNextPage();

    expect(cubit.state.posts.length, 10);
    expect(cubit.state.loadMoreError, isNotNull);
    expect(cubit.state.page, 1); // страница не засчитана — можно повторить
  });

  test('Валидация формы создания поста', () {
    expect(PostValidators.title('abc'), isNotNull); // < 5
    expect(PostValidators.title('Hello'), isNull);
    expect(PostValidators.body('short'), isNotNull); // < 10
    expect(PostValidators.body('long enough body'), isNull);
    expect(PostValidators.userId(null), isNotNull);
  });
}
