import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import '../widgets/state_views.dart';

/// Информация об авторе (GET /users/{id}) и его посты (GET /posts?userId=)
class AuthorScreen extends StatefulWidget {
  const AuthorScreen({super.key, required this.userId});

  final int userId;

  @override
  State<AuthorScreen> createState() => _AuthorScreenState();
}

class _AuthorScreenState extends State<AuthorScreen> {
  User? _user;
  List<Post> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = context.read<PostRepository>();
    try {
      final results = await Future.wait([
        repository.getUser(widget.userId),
        repository.getPostsByUser(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as User;
        _posts = results[1] as List<Post>;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_user?.name ?? 'Автор #${widget.userId}')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final user = _user!;
    final address = user.address; // вложенная модель
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                Text('@${user.username}'),
                const SizedBox(height: 8),
                if (user.email != null) _info(Icons.mail, user.email!),
                if (user.phone != null) _info(Icons.phone, user.phone!),
                if (user.website != null) _info(Icons.language, user.website!),
                if (address != null)
                  _info(Icons.home, '${address.city ?? ''}, ${address.street ?? ''}'),
                if (user.company != null) _info(Icons.business, user.company!.name),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Посты автора (${_posts.length})',
            style: Theme.of(context).textTheme.titleMedium),
        for (final p in _posts)
          ListTile(
            dense: true,
            leading: Text('#${p.id}'),
            title: Text(p.title),
          ),
      ],
    );
  }

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
