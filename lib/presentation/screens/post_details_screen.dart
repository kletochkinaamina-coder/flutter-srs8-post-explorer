import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/comment.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../widgets/state_views.dart';
import 'author_screen.dart';

/// Детали поста + комментарии
class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({
    super.key,
    required this.post,
    required this.authorName,
  });

  final Post post;
  final String authorName;

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late Post _post = widget.post;
  List<Comment> _comments = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Локальный пост сервер не знает — запрашивать нечего
    if (!widget.post.isLocal) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = context.read<PostRepository>();
    try {
      // Два запроса параллельно: GET /posts/{id} и GET /posts/{id}/comments
      final results = await Future.wait([
        repository.getPost(widget.post.id),
        repository.getComments(widget.post.id),
      ]);
      if (!mounted) return;
      setState(() {
        _post = results[0] as Post;
        _comments = results[1] as List<Comment>;
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
      appBar: AppBar(title: Text('Пост #${_post.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_post.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ActionChip(
            avatar: const Icon(Icons.person, size: 18),
            label: Text(widget.authorName),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AuthorScreen(userId: _post.userId)),
            ),
          ),
          const SizedBox(height: 12),
          Text(_post.body, style: const TextStyle(fontSize: 16)),
          const Divider(height: 32),
          Text('Комментарии', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._buildComments(),
        ],
      ),
    );
  }

  List<Widget> _buildComments() {
    if (_post.isLocal) {
      return const [
        EmptyView(
          message:
              'Пост создан локально. JSONPlaceholder его не хранит, поэтому комментариев нет.',
        ),
      ];
    }
    if (_loading) {
      return const [Center(child: CircularProgressIndicator())];
    }
    if (_error != null) {
      return [ErrorView(message: _error!, onRetry: _load)];
    }
    if (_comments.isEmpty) {
      return const [EmptyView(message: 'Комментариев нет')];
    }
    return [
      for (final c in _comments)
        Card(
          child: ListTile(
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${c.email ?? ''}\n${c.body}'),
            isThreeLine: true,
          ),
        ),
    ];
  }
}
