import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:srs8_app/core/error/app_exception.dart';
import 'package:srs8_app/data/models/post.dart';
import 'package:srs8_app/data/models/user.dart';

void main() {
  group('Post JSON', () {
    test('1. JSON успешно превращается в Post', () {
      final post = Post.fromJson({
        'userId': 1,
        'id': 7,
        'title': 'Hello',
        'body': 'World text',
      });

      expect(post.id, 7);
      expect(post.userId, 1);
      expect(post.title, 'Hello');
      expect(post.body, 'World text');
      expect(post.isLocal, false); // поля нет в JSON — значение по умолчанию
    });

    test('2. Post превращается обратно в JSON', () {
      const post = Post(id: 3, userId: 2, title: 'T', body: 'B', isLocal: true);

      expect(post.toJson(), {
        'id': 3,
        'userId': 2,
        'title': 'T',
        'body': 'B',
        'isLocal': true,
      });
    });

    test('нет обязательного поля -> понятная ошибка parse, без падения', () {
      // нет id и title
      Object? caught;
      try {
        Post.fromJson({'userId': 1, 'body': 'x'});
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<CheckedFromJsonException>());
      expect(AppException.from(caught!).type, AppErrorType.parse);
    });
  });

  test('User с вложенными Address/Geo/Company', () {
    final user = User.fromJson({
      'id': 1,
      'name': 'Leanne Graham',
      'username': 'Bret',
      'address': {
        'city': 'Gwenborough',
        'geo': {'lat': '-37.3159', 'lng': '81.1496'},
      },
      'company': {'name': 'Romaguera-Crona'},
    });

    expect(user.address?.city, 'Gwenborough');
    expect(user.address?.geo?.lat, '-37.3159');
    expect(user.company?.name, 'Romaguera-Crona');
    expect(user.phone, isNull); // необязательное поле
    expect((user.toJson()['address'] as Map)['geo'], isA<Map>());
  });
}
