import 'package:flutter/material.dart';

import '../../data/models/post.dart';

/// Карточка поста в списке
class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.post,
    required this.authorName,
    required this.onTap,
  });

  final Post post;
  final String authorName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text('${post.id}')),
        title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(authorName),
            if (post.isLocal)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'создан локально',
                  style: TextStyle(fontSize: 12, color: Colors.deepOrange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
