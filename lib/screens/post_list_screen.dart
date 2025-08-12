import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couchbase_lite_flutter_demo/models/post_model.dart';
import 'package:couchbase_lite_flutter_demo/providers/post_provider.dart';
import 'package:couchbase_lite_flutter_demo/screens/edit_post_screen.dart';
import 'package:couchbase_lite_flutter_demo/utils/snackbar_helper.dart';
import 'package:couchbase_lite_flutter_demo/widgets/loading_widget.dart';
import 'package:couchbase_lite_flutter_demo/widgets/post_card.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadSavedPosts();
    });
  }

  Future<void> _refreshPosts() async {
    await context.read<PostProvider>().loadSavedPosts();
  }

  Future<void> _editPost(PostModel post) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditPostScreen(post: post),
      ),
    );

    if (result == true && mounted) {
      SnackBarHelper.showSuccess(context, 'Post updated successfully! ✏️');
      _refreshPosts();
    }
  }

  Future<void> _deletePost(PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "${post.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final postProvider = context.read<PostProvider>();
      final success = await postProvider.deletePost(post.id);
      
      if (success && mounted) {
        SnackBarHelper.showSuccess(context, 'Post deleted successfully! 🗑️');
      } else if (mounted) {
        SnackBarHelper.showError(
          context,
          postProvider.errorMessage ?? 'Failed to delete post',
        );
      }
    }
  }

  Future<void> _clearAllPosts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Posts'),
        content: const Text('Are you sure you want to delete all saved posts? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final postProvider = context.read<PostProvider>();
      await postProvider.clearAllSavedPosts();
      
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'All posts cleared! 🧹');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Posts'),
        actions: [
          Consumer<PostProvider>(
            builder: (context, postProvider, child) {
              if (postProvider.savedPosts.isNotEmpty) {
                return PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'refresh':
                        _refreshPosts();
                        break;
                      case 'clear_all':
                        _clearAllPosts();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Refresh'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Clear All', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return IconButton(
                onPressed: _refreshPosts,
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          if (postProvider.isLoadingPosts) {
            return const Center(
              child: LoadingWidget(
                message: 'Loading saved posts...',
                size: 32,
              ),
            );
          }

          if (postProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    postProvider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refreshPosts,
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    label: Text(
                      'Retry',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (postProvider.savedPosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Saved Posts',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posts you save from the home tab will appear here.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _refreshPosts,
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      'Refresh',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshPosts,
            child: Column(
              children: [
                // Stats Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.storage,
                            size: 18,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Saved Posts: ${postProvider.savedPostsCount}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.storage,
                            size: 18,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Posts List
                Expanded(
                  child: ListView.builder(
                    itemCount: postProvider.savedPosts.length,
                    itemBuilder: (context, index) {
                      final post = postProvider.savedPosts[index];
                      return CompactPostCard(
                        post: post,
                        onTap: () => _editPost(post),
                        onEdit: () => _editPost(post),
                        onDelete: () => _deletePost(post),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          if (postProvider.savedPosts.isEmpty) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: _refreshPosts,
            tooltip: 'Refresh Posts',
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.refresh),
          );
        },
      ),
    );
  }
}