import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/create_post_request.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';

/// Своё состояние у формы — отправка не зависит от загрузки списка.
enum CreatePostStatus { initial, sending, success, error }

class CreatePostState {
  final CreatePostStatus status;
  final Post? created;
  final String? errorMessage;

  const CreatePostState({
    this.status = CreatePostStatus.initial,
    this.created,
    this.errorMessage,
  });
}

class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit(this._repository) : super(const CreatePostState());

  final PostRepository _repository;

  Future<void> submit({
    required String title,
    required String body,
    required int userId,
  }) async {
    // Блокируем повторную отправку, пока идёт запрос
    if (state.status == CreatePostStatus.sending) return;

    emit(const CreatePostState(status: CreatePostStatus.sending));
    try {
      final post = await _repository.createPost(
        CreatePostRequest(title: title.trim(), body: body.trim(), userId: userId),
      );
      emit(CreatePostState(status: CreatePostStatus.success, created: post));
    } on AppException catch (e) {
      emit(CreatePostState(
        status: CreatePostStatus.error,
        errorMessage: e.message,
      ));
    }
  }
}

/// Проверки полей формы (вынесены отдельно, чтобы их можно было протестировать)
class PostValidators {
  static String? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите заголовок';
    if (v.length < 5) return 'Минимум 5 символов';
    if (v.length > 100) return 'Максимум 100 символов';
    return null;
  }

  static String? body(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите текст поста';
    if (v.length < 10) return 'Минимум 10 символов';
    if (v.length > 1000) return 'Максимум 1000 символов';
    return null;
  }

  static String? userId(int? value) =>
      value == null ? 'Выберите автора' : null;
}
