import 'dart:async';
import 'package:cbl/cbl.dart';
import 'package:couchbase_lite_flutter_demo/models/post_model.dart';

enum SyncStatus {
  idle,
  connecting,
  active,
  error,
  stopped
}

const USER_NAME = "admin";
const PASSWORD = "Admin@123";

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static Replicator? _replicator;
  static const String _databaseName = 'mindweave_posts';
  static const String _collectionName = 'posts';
  static const String _indexDocId = 'post_index';

  ListenerToken? _liveQueryToken;
  final _postsController = StreamController<List<PostModel>>.broadcast();

  Stream<List<PostModel>> get livePostsStream => _postsController.stream;
  
  // App Services configuration
  static const String _appServicesUrl = 'wss://ucledcbvi7byidag.apps.cloud.couchbase.com:4984/sathya-couchbase';
  
  // Sync status management
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _currentSyncStatus = SyncStatus.idle;
  String? _lastSyncError;
  
  DatabaseService._();
  
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  // Sync status getters
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  SyncStatus get currentSyncStatus => _currentSyncStatus;
  String? get lastSyncError => _lastSyncError;

  // Initialize the database
  Future<void> initialize() async {
    try {
      if (_database != null) return;

      // Open or create database
      _database = await Database.openAsync(_databaseName);
      
      // Create indexes for better query performance
      await _createIndexes();
      
      print('✅ CouchbaseLite database initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize database: $e');
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  // Create indexes for better performance
  Future<void> _createIndexes() async {
    try {
      final collection = await _database!.defaultCollection;
      
      // Create index on type field for faster queries
      await collection.createIndex(
        'type_index',
        IndexBuilder.valueIndex([ValueIndexItem.expression(Expression.property('type'))]),
      );
      
      // Create index on id field
      await collection.createIndex(
        'id_index',
        IndexBuilder.valueIndex([ValueIndexItem.expression(Expression.property('id'))]),
      );
      
      print('✅ Database indexes created');
    } catch (e) {
      print('⚠️ Failed to create indexes: $e');
    }
  }

  // Save or update a post and update index
  Future<bool> savePost(PostModel post) async {
    try {
      await _ensureDatabaseInitialized();
      
      // Ensure replicator is running
      if (_replicator == null || (await _replicator!.status).activity == ReplicatorActivityLevel.stopped) {
        print('⚠️ Replicator not running, attempting to start sync');
        final syncStarted = await startSync();
        if (!syncStarted) {
          throw DatabaseException('Cannot save post: Sync not active');
        }
      }
      
      // Validate and sanitize document ID
      final docId = _validateDocumentId(post.id);
      print('💾 Attempting to save post with ID: $docId (original: ${post.id})');
      
      final collection = await _database!.defaultCollection;
      
      // Check if post already exists
      final existingDoc = await collection.document(docId);
      
      if (existingDoc != null) {
        // Update existing post
        final mutableDoc = existingDoc.toMutable();
        mutableDoc.setData(post.toDocument());
        await collection.saveDocument(mutableDoc);
        print('📝 Updated post: $docId');
      } else {
        // Create new post
        final doc = MutableDocument.withId(docId);
        doc.setData(post.toDocument());
        await collection.saveDocument(doc);
        print('💾 Saved new post: $docId');
        
        // Update index
        await _addToIndex(docId);
      }
      
      return true;
    } catch (e) {
      print('❌ Failed to save post: $e');
      throw DatabaseException('Failed to save post: $e');
    }
  }

  // Get all posts using index document
  Future<List<PostModel>> getAllPosts() async {
    try {
      await _ensureDatabaseInitialized();
      
      final collection = await _database!.defaultCollection;
      final posts = <PostModel>[];
      
      // Get post IDs from index
      final postIds = await _getPostIdsFromIndex();
      
      // Retrieve each post
      for (final postId in postIds) {
        try {
          final document = await collection.document(postId);
          if (document != null) {
            final data = document.toPlainMap();
            if (data['type'] == 'post') {
              posts.add(PostModel.fromDocument(data));
            }
          }
        } catch (e) {
          print('⚠️ Error loading post $postId: $e');
        }
      }
      
      // Sort by updated date (newest first)
      posts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      print('📋 Retrieved ${posts.length} posts from database');
      return posts;
    } catch (e) {
      print('❌ Failed to get posts: $e');
      throw DatabaseException('Failed to retrieve posts: $e');
    }
  }

  // Get a specific post by ID (simple document lookup)
  Future<PostModel?> getPostById(String postId) async {
    try {
      await _ensureDatabaseInitialized();
      
      final docId = _validateDocumentId(postId);
      final collection = await _database!.defaultCollection;
      final document = await collection.document(docId);
      
      if (document != null) {
        final data = document.toPlainMap();
        if (data['type'] == 'post') {
          return PostModel.fromDocument(data);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Failed to get post by ID: $e');
      throw DatabaseException('Failed to get post: $e');
    }
  }

  // Update a post
  Future<bool> updatePost(PostModel post) async {
    try {
      await _ensureDatabaseInitialized();
      
      final docId = _validateDocumentId(post.id);
      final collection = await _database!.defaultCollection;
      final doc = await collection.document(docId);
      
      if (doc != null) {
        final mutableDoc = doc.toMutable();
        mutableDoc.setData(post.toDocument());
        await collection.saveDocument(mutableDoc);
        print('✏️ Updated post: $docId');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Failed to update post: $e');
      throw DatabaseException('Failed to update post: $e');
    }
  }

  // Delete a post and update index
  Future<bool> deletePost(String postId) async {
    try {
      await _ensureDatabaseInitialized();
      
      final docId = _validateDocumentId(postId);
      final collection = await _database!.defaultCollection;
      final doc = await collection.document(docId);
      
      if (doc != null) {
        await collection.deleteDocument(doc);
        await _removeFromIndex(docId);
        print('🗑️ Deleted post: $docId');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Failed to delete post: $e');
      throw DatabaseException('Failed to delete post: $e');
    }
  }

  // Get posts count
  Future<int> getPostsCount() async {
    try {
      await _ensureDatabaseInitialized();
      
      final posts = await getAllPosts();
      return posts.length;
    } catch (e) {
      print('❌ Failed to get posts count: $e');
      return 0;
    }
  }

  // Check if post exists
  Future<bool> postExists(String postId) async {
    try {
      await _ensureDatabaseInitialized();
      final docId = _validateDocumentId(postId);
      final collection = await _database!.defaultCollection;
      final doc = await collection.document(docId);
      return doc != null;
    } catch (e) {
      print('❌ Failed to check if post exists: $e');
      return false;
    }
  }

  // Clear all posts (for testing)
  Future<void> clearAllPosts() async {
    try {
      await _ensureDatabaseInitialized();
      
      final collection = await _database!.defaultCollection;
      final postIds = await _getPostIdsFromIndex();
      
      // Delete all posts
      for (final postId in postIds) {
        final doc = await collection.document(postId);
        if (doc != null) {
          await collection.deleteDocument(doc);
        }
      }
      
      // Clear index
      await _clearIndex();
      
      print('🧹 Cleared all posts from database');
    } catch (e) {
      print('❌ Failed to clear posts: $e');
      throw DatabaseException('Failed to clear posts: $e');
    }
  }

  // Ensure database is initialized
  Future<void> _ensureDatabaseInitialized() async {
    if (_database == null) {
      await initialize();
    }
  }

  // Validate and sanitize document ID for CouchbaseLite compatibility
  String _validateDocumentId(String originalId) {
    if (originalId.isEmpty) {
      throw DatabaseException('Document ID cannot be empty');
    }
    
    String sanitized = originalId.trim();
    
    if (sanitized.startsWith('_')) {
      sanitized = 'doc$sanitized';
    }
    
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\-\.]'), '_');
    
    if (sanitized.isEmpty) {
      sanitized = 'post_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return sanitized;
  }

  // Close database connection
  Future<void> close() async {
    try {
      await stopSync();
      await _database?.close();
      _database = null;
      await _syncStatusController.close();
      print('🔒 Database connection closed');
    } catch (e) {
      print('❌ Failed to close database: $e');
    }
  }

  // === SYNC FUNCTIONALITY ===
  
  // Start synchronization with App Services
  Future<bool> startSync() async {
    try {
      await _ensureDatabaseInitialized();
      
      if (_replicator != null) {
        final status = await _replicator!.status;
        if (status.activity != ReplicatorActivityLevel.stopped) {
          print('🔄 Replicator already running');
          return true;
        }
        await _replicator!.stop();
        _replicator = null;
      }
      
      _updateSyncStatus(SyncStatus.connecting);
      
      // Validate URL
      if (!_appServicesUrl.startsWith('wss://')) {
        throw DatabaseException('Invalid App Services URL: Must use wss://');
      }
      
      // Configure replicator
      final endpoint = UrlEndpoint(Uri.parse(_appServicesUrl));
      
      ReplicatorConfiguration config = ReplicatorConfiguration(
        database: _database!,
        target: endpoint,
      );
      
      // Set replication type (push and pull)
      config.replicatorType = ReplicatorType.pushAndPull;
      
      // Set continuous mode
      config.continuous = true;
      
      // Add authentication
      config.authenticator = BasicAuthenticator(
        username: USER_NAME,
        password: PASSWORD,
      );
      
      // Configure channels for posts
      config.channels = ['posts']; // Matches App Services sync function
      
      // Create replicator
      _replicator = await Replicator.create(config);
      
      // Add status change listener
      _replicator!.addChangeListener(_onReplicatorStatusChanged);
      
      // Start replication
      await _replicator!.start();
      
      print('🚀 Sync started with App Services: $_appServicesUrl');
      return true;
      
    } catch (e, stackTrace) {
      print('❌ Failed to start sync: $e StackTrace: $stackTrace');
      _lastSyncError = 'Failed to start sync: $e';
      _updateSyncStatus(SyncStatus.error);
      return false;
    }
  }
  
  // Stop synchronization
  Future<void> stopSync() async {
    try {
      if (_replicator != null) {
        await _replicator!.stop();
        _replicator = null;
        _updateSyncStatus(SyncStatus.stopped);
        print('⏹️ Sync stopped');
      }
    } catch (e) {
      print('❌ Failed to stop sync: $e');
      _lastSyncError = 'Failed to stop sync: $e';
      _updateSyncStatus(SyncStatus.error);
    }
  }
  
  // Test connection to App Services
  Future<bool> testConnection() async {
    try {
      _updateSyncStatus(SyncStatus.connecting);
      
      // Attempt to connect briefly to test
      final success = await startSync();
      if (success) {
        // Stop immediately after successful connection test
        await Future.delayed(Duration(seconds: 2));
        await stopSync();
        print('✅ Connection test successful');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Connection test failed: $e');
      _lastSyncError = 'Connection test failed: $e';
      _updateSyncStatus(SyncStatus.error);
      return false;
    }
  }
  
  // Get current replicator status
  Future<String> getReplicatorStatusText() async {
    if (_replicator == null) return 'Not initialized';
    
    final status = await _replicator!.status;
    final activity = status.activity;
    
    String statusText = activity.name;
    
    if (status.error != null) {
      statusText += ' - Error: ${status.error}';
    }
    
    return statusText;
  }
  
  // Verify if a post has synced to the cloud (for debugging)
  Future<bool> isPostSynced(String postId) async {
    try {
      final docId = _validateDocumentId(postId);
      if (_replicator == null || (await _replicator!.status).activity == ReplicatorActivityLevel.stopped) {
        print('⚠️ Cannot verify sync: Replicator not running');
        return false;
      }
      
      // Wait for sync to complete (simplified check)
      await Future.delayed(Duration(seconds: 2)); // Adjust based on network
      final status = await _replicator!.status;
      if (status.activity == ReplicatorActivityLevel.idle && status.error == null) {
        print('✅ Post $docId likely synced (replicator idle)');
        return true;
      } else {
        print('⚠️ Post $docId sync status unclear: Replicator ${status.activity.name}');
        return false;
      }
    } catch (e) {
      print('❌ Failed to verify post sync: $e');
      return false;
    }
  }
  
  // Private method to handle replicator status changes
  void _onReplicatorStatusChanged(ReplicatorChange change) {
    final status = change.status;
    print('🔄 Replicator status: ${status.activity.name}');
    
    switch (status.activity) {
      case ReplicatorActivityLevel.busy:
        _updateSyncStatus(SyncStatus.active);
        break;
      case ReplicatorActivityLevel.idle:
        _updateSyncStatus(SyncStatus.idle);
        break;
      case ReplicatorActivityLevel.connecting:
        _updateSyncStatus(SyncStatus.connecting);
        break;
      case ReplicatorActivityLevel.stopped:
        _updateSyncStatus(SyncStatus.stopped);
        break;
      case ReplicatorActivityLevel.offline:
        _updateSyncStatus(SyncStatus.error);
        break;
    }
    
    if (status.error != null) {
      _lastSyncError = status.error.toString();
      _updateSyncStatus(SyncStatus.error);
      print('❌ Replicator error: ${status.error}');
    }
    
    print('📊 Replicator activity: ${status.activity.name}');
  }
  
  // Update sync status and notify listeners
  void _updateSyncStatus(SyncStatus status) {
    if (_currentSyncStatus != status) {
      _currentSyncStatus = status;
      _syncStatusController.add(status);
      print('📡 Sync status updated: ${status.name}');
    }
  }

  // Index management methods
  Future<List<String>> _getPostIdsFromIndex() async {
    try {
      final collection = await _database!.defaultCollection;
      final indexDoc = await collection.document(_indexDocId);
      
      if (indexDoc != null) {
        final data = indexDoc.toPlainMap();
        final postIds = data['postIds'] as List<dynamic>?;
        return postIds?.cast<String>() ?? [];
      }
      
      return [];
    } catch (e) {
      print('⚠️ Failed to get post IDs from index: $e');
      return [];
    }
  }

  Future<void> _addToIndex(String postId) async {
    try {
      print('📇 Adding to index: $postId (Index doc ID: $_indexDocId)');
      final collection = await _database!.defaultCollection;
      final indexDoc = await collection.document(_indexDocId);
      List<String> postIds;

      if (indexDoc != null) {
        final data = indexDoc.toPlainMap();
        postIds = (data['postIds'] as List<dynamic>?)?.cast<String>() ?? [];
        print('📇 Found existing index with ${postIds.length} posts');
      } else {
        postIds = [];
        print('📇 Creating new index document');
      }

      if (!postIds.contains(postId)) {
        postIds.add(postId);
        
        final mutableDoc = indexDoc?.toMutable() ?? MutableDocument.withId(_indexDocId);
        mutableDoc.setData({'postIds': postIds});
        await collection.saveDocument(mutableDoc);
        print('✅ Successfully added $postId to index. Total posts: ${postIds.length}');
      } else {
        print('ℹ️ Post $postId already exists in index');
      }
    } catch (e) {
      print('❌ Failed to add to index: $e');
      print('❌ Post ID: $postId, Index doc ID: $_indexDocId');
    }
  }

  Future<void> _removeFromIndex(String postId) async {
    try {
      final collection = await _database!.defaultCollection;
      final indexDoc = await collection.document(_indexDocId);

      if (indexDoc != null) {
        final data = indexDoc.toPlainMap();
        final postIds = (data['postIds'] as List<dynamic>?)?.cast<String>() ?? [];
        
        if (postIds.remove(postId)) {
          final mutableDoc = indexDoc.toMutable();
          mutableDoc.setData({'postIds': postIds});
          await collection.saveDocument(mutableDoc);
        }
      }
    } catch (e) {
      print('⚠️ Failed to remove from index: $e');
    }
  }

  Future<void> _clearIndex() async {
    try {
      final collection = await _database!.defaultCollection;
      final indexDoc = await collection.document(_indexDocId);

      if (indexDoc != null) {
        await collection.deleteDocument(indexDoc);
      }
    } catch (e) {
      print('⚠️ Failed to clear index: $e');
    }
  }

    // Start live query for posts
  Future<void> startLiveQuery() async {
    await _ensureDatabaseInitialized();
    final collection = await _database!.defaultCollection;

    // Build the query using QueryBuilder
    final query = QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property('type').equalTo(Expression.string('post')));

    // Add change listener for live updates
    _liveQueryToken = await query.addChangeListener((change) async {
      final posts = <PostModel>[];
      final results = change.results;
      final resultsall = await results.allResults();
      for (final result in resultsall) {
        final data = result.toPlainMap()[_collectionName];
        if (data is Map<String, dynamic> && data['type'] == 'post') {
          posts.add(PostModel.fromDocument(data));
        }
      }
        posts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Newest first
      _postsController.add(posts);
      print('📋 Live query: ${posts.length} posts updated');
    });

    // Initial execution to trigger listener
    await query.execute();
  }

    // Stop live query when not needed
    Future<void> stopLiveQuery() async {
      if (_liveQueryToken != null) {
        // ListenerToken doesn't have a remove method; it's managed by the query
        // Simply nullify the token, as the listener is tied to the query lifecycle
        _liveQueryToken = null;
      }
      await _postsController.close();
    }
}

class DatabaseException implements Exception {
  final String message;
  
  DatabaseException(this.message);
  
  @override
  String toString() => 'DatabaseException: $message';
}