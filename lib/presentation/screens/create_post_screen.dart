import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import '../state/create_post_cubit.dart';

/// Экран создания поста (POST /posts)
class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key, required this.users});

  final List<User> users;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreatePostCubit(context.read<PostRepository>()),
      child: _CreatePostView(users: users),
    );
  }
}

class _CreatePostView extends StatefulWidget {
  const _CreatePostView({required this.users});

  final List<User> users;

  @override
  State<_CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<_CreatePostView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  int? _userId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    // Проверяем данные ДО отправки
    if (!_formKey.currentState!.validate()) return;
    context.read<CreatePostCubit>().submit(
          title: _titleController.text,
          body: _bodyController.text,
          userId: _userId!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый пост')),
      body: BlocConsumer<CreatePostCubit, CreatePostState>(
        listener: (context, state) {
          if (state.status == CreatePostStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Ошибка'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == CreatePostStatus.success) {
            return _buildResult(state);
          }
          return _buildForm(state.status == CreatePostStatus.sending);
        },
      ),
    );
  }

  Widget _buildForm(bool sending) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            enabled: !sending,
            maxLength: 100,
            validator: PostValidators.title,
            decoration: const InputDecoration(
              labelText: 'Заголовок *',
              helperText: 'От 5 до 100 символов',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bodyController,
            enabled: !sending,
            maxLength: 1000,
            maxLines: 6,
            validator: PostValidators.body,
            decoration: const InputDecoration(
              labelText: 'Текст *',
              helperText: 'От 10 до 1000 символов',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _userId,
            validator: PostValidators.userId,
            items: [
              for (final u in widget.users)
                DropdownMenuItem(value: u.id, child: Text(u.name)),
            ],
            onChanged: sending ? null : (v) => setState(() => _userId = v),
            decoration: InputDecoration(
              labelText: 'Автор *',
              border: const OutlineInputBorder(),
              helperText: widget.users.isEmpty
                  ? 'Не удалось загрузить авторов — проверьте интернет'
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              // Пока идёт запрос, кнопка заблокирована
              onPressed: sending ? null : _submit,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(sending ? 'Отправка…' : 'Отправить'),
            ),
          ),
        ],
      ),
    );
  }

  // Показываем объект, который вернул сервер
  Widget _buildResult(CreatePostState state) {
    final post = state.created!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 56),
        const SizedBox(height: 8),
        const Text(
          'Сервер принял пост',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ответ сервера:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('id: ${post.id}'),
                Text('userId: ${post.userId}'),
                Text('title: ${post.title}'),
                Text('body: ${post.body}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'JSONPlaceholder не сохраняет новые посты. Пост добавлен в список '
          'с пометкой «создан локально».',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context, post),
          child: const Text('К списку'),
        ),
      ],
    );
  }
}
