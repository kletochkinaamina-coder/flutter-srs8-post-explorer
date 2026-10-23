import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../state/posts_cubit.dart';
import '../state/posts_state.dart';
import '../widgets/post_tile.dart';
import '../widgets/state_views.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';

/// Главный экран: список постов, поиск, фильтр, сортировка, пагинация.
class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Почти докрутили до конца — просим следующую страницу
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<PostsCubit>().loadNextPage();
    }
  }

  Future<void> _openCreate() async {
    final cubit = context.read<PostsCubit>();
    final created = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen(users: cubit.state.users)),
    );
    if (created != null) cubit.addLocalPost(created);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsCubit, PostsState>(
      builder: (context, state) {
        final cubit = context.read<PostsCubit>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Post Explorer'),
            actions: [
              IconButton(
                tooltip: 'Сортировка по ID',
                icon: Icon(
                  state.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onPressed: cubit.toggleSort,
              ),
              IconButton(
                tooltip: 'Сбросить фильтры',
                icon: const Icon(Icons.filter_alt_off),
                onPressed: () {
                  _searchController.clear();
                  cubit.resetFilters();
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            label: const Text('Новый пост'),
          ),
          body: Column(
            children: [
              _buildFilters(state, cubit),
              if (state.status == PostsStatus.cached)
                CachedBanner(savedAt: state.cachedAt, error: state.errorMessage),
              Expanded(child: _buildBody(state, cubit)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(PostsState state, PostsCubit cubit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: cubit.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Поиск по заголовку',
              // Явно пишем, где ищем
              helperText:
                  'Ищем среди загруженных постов (${state.posts.length + state.localPosts.length})',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_search, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: state.userId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все посты')),
                    for (final u in state.users)
                      DropdownMenuItem(value: u.id, child: Text(u.name)),
                  ],
                  onChanged: cubit.selectAuthor,
                ),
              ),
              Text(
                state.ascending ? 'ID ↑' : 'ID ↓',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PostsState state, PostsCubit cubit) {
    // Первая загрузка без кэша
    if (state.status == PostsStatus.loading ||
        state.status == PostsStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    // Ошибка и показать нечего
    if (state.status == PostsStatus.error && state.visiblePosts.isEmpty) {
      return ErrorView(
        message: state.errorMessage ?? 'Ошибка загрузки',
        onRetry: cubit.loadFirstPage,
      );
    }

    final posts = state.visiblePosts;

    return RefreshIndicator(
      onRefresh: cubit.loadFirstPage,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: posts.length + 1, // +1 — строка внизу списка
        itemBuilder: (context, index) {
          if (index == posts.length) return _buildFooter(state, cubit, posts);
          final post = posts[index];
          return PostTile(
            post: post,
            authorName: state.authorName(post.userId),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailsScreen(
                  post: post,
                  authorName: state.authorName(post.userId),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Низ списка: загрузка / ошибка страницы / конец / пусто
  Widget _buildFooter(PostsState state, PostsCubit cubit, List<Post> posts) {
    if (posts.isEmpty) {
      return EmptyView(
        message: state.query.isNotEmpty
            ? 'Среди загруженных постов ничего не найдено'
            : 'Постов нет',
      );
    }
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(state.loadMoreError!, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: cubit.loadNextPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (!state.hasMore && state.page > 0) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 88),
        child: Center(
          child: Text('Больше постов нет', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return const SizedBox(height: 88); // место под кнопку «Новый пост»
  }
}
