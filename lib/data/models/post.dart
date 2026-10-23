import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

/// Пост. checked: true — при плохом JSON будет понятная
/// CheckedFromJsonException, а не падение где-то внутри.
@JsonSerializable(checked: true)
class Post extends Equatable {
  final int id;
  final int userId;
  final String title;

  // Если сервер не прислал body — подставим пустую строку
  @JsonKey(defaultValue: '')
  final String body;

  /// true — пост создан в приложении. Сервер JSONPlaceholder его не хранит.
  @JsonKey(defaultValue: false)
  final bool isLocal;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isLocal = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);

  Post copyWith({bool? isLocal}) => Post(
        id: id,
        userId: userId,
        title: title,
        body: body,
        isLocal: isLocal ?? this.isLocal,
      );

  @override
  List<Object?> get props => [id, userId, title, body, isLocal];
}
