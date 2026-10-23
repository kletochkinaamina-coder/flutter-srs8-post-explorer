import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srs8_app/core/error/app_exception.dart';
import 'package:srs8_app/data/local/post_cache.dart';
import 'package:srs8_app/data/models/create_post_request.dart';
import 'package:srs8_app/data/models/post.dart';
import 'package:srs8_app/data/remote/post_api.dart';
import 'package:srs8_app/data/repositories/post_repository.dart';

/// Тесты репозитория через mock-адаптер Dio — реальный интернет не нужен.
void main() {
  late Dio dio;
  late DioAdapter adapter;
  late PostRepository repository;

  const page1Query = {'_page': 1, '_limit': 10, '_sort': 'id', '_order': 'asc'};

  Map<String, dynamic> postJson(int id) =>
      {'userId': 1, 'id': id, 'title': 'Post $id', 'body': 'Body $id'};

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    adapter = DioAdapter(dio: dio);
    repository = PostRepository(PostApi(dio), PostCache(prefs));
  });

  test('3. Успешная загрузка постов через репозиторий + запись в кэш', () async {
    adapter.onGet(
      '/posts',
      (server) => server.reply(200, [postJson(1), postJson(2)]),
      queryParameters: page1Query,
    );

    final posts = await repository.fetchPosts(page: 1);

    expect(posts.map((p) => p.id), [1, 2]);
    expect(repository.getCachedPosts()?.posts.length, 2);
  });

  test('4. Ошибка сервера 500 -> AppException.server, кэш не удаляется', () async {
    // Сначала успешная загрузка
    adapter.onGet('/posts', (s) => s.reply(200, [postJson(1)]),
        queryParameters: page1Query);
    await repository.fetchPosts(page: 1);

    // Затем сервер падает
    adapter.onGet('/posts', (s) => s.reply(500, {'error': 'boom'}),
        queryParameters: page1Query);

    await expectLater(
      repository.fetchPosts(page: 1),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.server)
          .having((e) => e.statusCode, 'statusCode', 500)),
    );
    // Последний успешный результат остался
    expect(repository.getCachedPosts()?.posts.single.id, 1);
  });

  test('404 -> AppException.client', () async {
    adapter.onGet('/posts/999', (s) => s.reply(404, {}));

    await expectLater(
      repository.getPost(999),
      throwsA(isA<AppException>().having((e) => e.type, 'type', AppErrorType.client)),
    );
  });

  test('Некорректный JSON от сервера -> AppException.parse, без падения', () async {
    adapter.onGet('/posts/1', (s) => s.reply(200, {'id': 'не число'}));

    await expectLater(
      repository.getPost(1),
      throwsA(isA<AppException>().having((e) => e.type, 'type', AppErrorType.parse)),
    );
  });

  test('POST /posts через mock-адаптер: пост помечается «создан локально»', () async {
    adapter.onPost(
      '/posts',
      (s) => s.reply(201, {'title': 'Новый пост', 'body': 'Текст поста', 'userId': 2, 'id': 101}),
      data: {'title': 'Новый пост', 'body': 'Текст поста', 'userId': 2},
    );

    final created = await repository.createPost(
      const CreatePostRequest(title: 'Новый пост', body: 'Текст поста', userId: 2),
    );

    expect(created.id, 101);
    expect(created.isLocal, true);
    expect(repository.getLocalPosts(), [created]);
  });

  group('5. Фильтрация', () {
    const posts = [
      Post(id: 1, userId: 1, title: 'Flutter is great', body: ''),
      Post(id: 2, userId: 2, title: 'Dart tips', body: ''),
      Post(id: 3, userId: 1, title: 'Learning FLUTTER', body: ''),
    ];

    test('по заголовку (без учёта регистра)', () {
      final result = PostRepository.filterByTitle(posts, 'flutter');
      expect(result.map((p) => p.id), [1, 3]);
    });

    test('по автору', () {
      expect(PostRepository.filterByAuthor(posts, 2).map((p) => p.id), [2]);
      expect(PostRepository.filterByAuthor(posts, null).length, 3);
    });
  });
}
