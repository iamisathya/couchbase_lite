import 'package:flutter/foundation.dart';
import 'package:couchbase_lite_flutter_demo/models/post_model.dart';
import 'package:couchbase_lite_flutter_demo/services/api_service.dart';
import 'package:couchbase_lite_flutter_demo/services/database_service.dart';

class PostProvider with ChangeNotifier {
  // Current post being displayed/edited
  PostModel? _currentPost;
  
  // List of saved posts from CouchbaseLite
  List<PostModel> _savedPosts = [];
  
  // Loading states
  bool _isFetchingPost = false;
  bool _isSavingPost = false;
  bool _isLoadingPosts = false;
  bool _isDeletingPost = false;
  bool _isUpdatingPost = false;
  
  // Error handling
  String? _errorMessage;
  
  // Database service instance
  final DatabaseService _databaseService = DatabaseService.instance;

  // Getters
  PostModel? get currentPost => _currentPost;
  List<PostModel> get savedPosts => List.unmodifiable(_savedPosts);
  bool get isFetchingPost => _isFetchingPost;
  bool get isSavingPost => _isSavingPost;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get isDeletingPost => _isDeletingPost;
  bool get isUpdatingPost => _isUpdatingPost;
  String? get errorMessage => _errorMessage;
  bool get hasCurrentPost => _currentPost != null;
  int get savedPostsCount => _savedPosts.length;

  // Initialize provider
  Future<void> initialize() async {
    try {
      await _databaseService.initialize();
      await loadSavedPosts();
    } catch (e) {
      _setError('Failed to initialize: ${e.toString()}');
    }
  }

  // Fetch a random post from API
  Future<void> fetchRandomPost() async {
    _isFetchingPost = true;
    _clearError();
    notifyListeners();

    try {
      final post = await ApiService.fetchRandomPost();
      _currentPost = post;
      _isFetchingPost = false;
      notifyListeners();
    } catch (e) {
      _isFetchingPost = false;
      _setError('Failed to fetch post: ${e.toString()}');
      notifyListeners();
    }
  }

  // Update current post content (title/body)
  void updateCurrentPost({String? title, String? body}) {
    if (_currentPost == null) return;
    
    _currentPost!.updateContent(title: title, body: body);
    _clearError();
    notifyListeners();
  }

  // Save current post to CouchbaseLite
  Future<void> saveCurrentPost() async {
    if (_currentPost == null) return;

    _isSavingPost = true;
    _clearError();
    notifyListeners();

    try {
      final success = await _databaseService.savePost(_currentPost!);
      _isSavingPost = false;
      
      if (success) {
        // Refresh saved posts list
        await loadSavedPosts();
        notifyListeners();
      } else {
        _setError('Failed to save post to database');
        notifyListeners();
      }
    } catch (e) {
      _isSavingPost = false;
      _setError('Error saving post: ${e.toString()}');
      notifyListeners();
    }
  }

  // Load all saved posts from CouchbaseLite
  Future<void> loadSavedPosts() async {
    _isLoadingPosts = true;
    _clearError();
    notifyListeners();

    try {
      final posts = await _databaseService.getAllPosts();
      _savedPosts = posts;
      _isLoadingPosts = false;
      notifyListeners();
    } catch (e) {
      _isLoadingPosts = false;
      _setError('Failed to load saved posts: ${e.toString()}');
      notifyListeners();
    }
  }

  // Delete a saved post
  Future<bool> deletePost(String postId) async {
    _isDeletingPost = true;
    _clearError();
    notifyListeners();

    try {
      final success = await _databaseService.deletePost(postId);
      _isDeletingPost = false;
      
      if (success) {
        // Remove from local list
        _savedPosts.removeWhere((post) => post.id == postId);
        
        // Clear current post if it's the deleted one
        if (_currentPost?.id == postId) {
          _currentPost = null;
        }
        
        notifyListeners();
        return true;
      } else {
        _setError('Failed to delete post');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isDeletingPost = false;
      _setError('Error deleting post: ${e.toString()}');
      notifyListeners();
      return false;
    }
  }

  // Update a saved post
  Future<bool> updatePost(PostModel updatedPost) async {
    _isUpdatingPost = true;
    _clearError();
    notifyListeners();

    try {
      final success = await _databaseService.updatePost(updatedPost);
      _isUpdatingPost = false;
      
      if (success) {
        // Update in local list
        final index = _savedPosts.indexWhere((post) => post.id == updatedPost.id);
        if (index >= 0) {
          _savedPosts[index] = updatedPost;
        }
        
        // Update current post if it's the same
        if (_currentPost?.id == updatedPost.id) {
          _currentPost = updatedPost;
        }
        
        notifyListeners();
        return true;
      } else {
        _setError('Failed to update post');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isUpdatingPost = false;
      _setError('Error updating post: ${e.toString()}');
      notifyListeners();
      return false;
    }
  }

  // Set current post (for editing)
  void setCurrentPost(PostModel post) {
    _currentPost = post;
    _clearError();
    notifyListeners();
  }

  // Clear current post
  void clearCurrentPost() {
    _currentPost = null;
    _clearError();
    notifyListeners();
  }

  // Check if a post is already saved
  bool isPostSaved(String postId) {
    return _savedPosts.any((post) => post.id == postId);
  }

  // Get saved post by ID
  PostModel? getSavedPostById(String postId) {
    try {
      return _savedPosts.firstWhere((post) => post.id == postId);
    } catch (e) {
      return null;
    }
  }

  // Refresh data (fetch new post and reload saved posts)
  Future<void> refreshAll() async {
    await Future.wait([
      fetchRandomPost(),
      loadSavedPosts(),
    ]);
  }

  // Clear all saved posts (for testing)
  Future<void> clearAllSavedPosts() async {
    try {
      await _databaseService.clearAllPosts();
      _savedPosts.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear all posts: ${e.toString()}');
      notifyListeners();
    }
  }

  // Private helper methods
  void _setError(String error) {
    _errorMessage = error;
    debugPrint('PostProvider Error: $error');
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Check if any operation is in progress
  bool get isLoading => _isFetchingPost || _isSavingPost || _isLoadingPosts || _isDeletingPost || _isUpdatingPost;

  @override
  void dispose() {
    _databaseService.close();
    super.dispose();
  }
}