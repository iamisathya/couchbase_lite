import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couchbase_lite_flutter_demo/providers/post_provider.dart';
import 'package:couchbase_lite_flutter_demo/screens/post_list_screen.dart';
import 'package:couchbase_lite_flutter_demo/utils/snackbar_helper.dart';
import 'package:couchbase_lite_flutter_demo/widgets/loading_widget.dart';
import 'package:couchbase_lite_flutter_demo/widgets/post_card.dart';
import 'package:couchbase_lite_flutter_demo/widgets/action_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  String _titleController = '';
  String _bodyController = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize the provider and fetch first post
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postProvider = context.read<PostProvider>();
      postProvider.initialize().then((_) {
        if (mounted) {
          postProvider.fetchRandomPost();
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _fetchNewPost() async {
    final postProvider = context.read<PostProvider>();
    await postProvider.fetchRandomPost();
    
    if (mounted) {
      if (postProvider.currentPost != null) {
        SnackBarHelper.showSuccess(context, 'New post fetched! 🔄');
        // Reset editing fields
        _titleController = postProvider.currentPost!.title;
        _bodyController = postProvider.currentPost!.body;
      } else if (postProvider.errorMessage != null) {
        SnackBarHelper.showError(context, 'Failed to fetch post');
      }
    }
  }

  Future<void> _saveCurrentPost() async {
    final postProvider = context.read<PostProvider>();
    
    if (postProvider.currentPost == null) {
      SnackBarHelper.showWarning(context, 'No post to save');
      return;
    }

    // Check if post is already saved
    if (postProvider.isPostSaved(postProvider.currentPost!.id)) {
      SnackBarHelper.showInfo(context, 'Post already saved! 💾');
      return;
    }

    await postProvider.saveCurrentPost();
    
    if (mounted) {
      if (postProvider.errorMessage == null) {
        SnackBarHelper.showSuccess(context, 'Post saved to Couchbase! 💾');
      } else {
        SnackBarHelper.showError(
          context,
          postProvider.errorMessage ?? 'Failed to save post',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildHomePage(),
          const PostListScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Saved Posts',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MindWeave'),
        centerTitle: true,
        actions: [
          Consumer<PostProvider>(
            builder: (context, postProvider, child) {
              return IconButton(
                onPressed: postProvider.isLoading ? null : _fetchNewPost,
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Fetch new post',
              );
            },
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  color: postProvider.currentPost != null
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(
                          postProvider.currentPost != null
                              ? Icons.article
                              : Icons.warning,
                          color: postProvider.currentPost != null
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            postProvider.currentPost != null
                                ? 'Post loaded and ready to edit'
                                : 'No post available - fetch one to get started',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: postProvider.currentPost != null
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                
                
                // Post Content or Loading
                if (postProvider.isFetchingPost) ...[
                  const Center(
                    child: LoadingWidget(
                      message: 'Fetching random post...',
                      size: 32,
                    ),
                  ),
                ] else if (postProvider.currentPost != null) ...[
                  PostCard(
                    post: postProvider.currentPost!,
                    showActions: false,
                    isEditable: true,
                    onTitleChanged: (value) {
                      _titleController = value;
                      postProvider.updateCurrentPost(title: value);
                    },
                    onBodyChanged: (value) {
                      _bodyController = value;
                      postProvider.updateCurrentPost(body: value);
                    },
                  ),
                ] else if (postProvider.errorMessage != null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            postProvider.errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchNewPost,
                            icon: Icon(
                              Icons.refresh,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            label: Text(
                              'Try Again',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Action Buttons
                if (postProvider.currentPost != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          text: 'Refresh',
                          icon: Icons.refresh,
                          onPressed: postProvider.isLoading ? null : _fetchNewPost,
                          isLoading: postProvider.isFetchingPost,
                          isOutlined: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ActionButton(
                          text: 'Save to DB',
                          icon: Icons.save,
                          onPressed: postProvider.isLoading ? null : _saveCurrentPost,
                          isLoading: postProvider.isSavingPost,
                          backgroundColor: postProvider.isPostSaved(postProvider.currentPost!.id)
                              ? Theme.of(context).colorScheme.tertiary
                              : null,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                 
                ],
                
                const SizedBox(height: 24),
                
                // Database Stats
                Consumer<PostProvider>(
                  builder: (context, postProvider, child) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.storage,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Database Statistics',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saved Posts:',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  '${postProvider.savedPostsCount}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (postProvider.savedPosts.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Last Updated:',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    _formatDateTime(postProvider.savedPosts.first.updatedAt),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}