import 'dart:async';
import 'package:cbl/cbl.dart';
import 'package:couchbase_lite_flutter_demo/models/post_model.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static const String _databaseName = 'mindweave_posts';
  static const String _collectionName = 'posts';
  static const String _indexDocId = 'post_index';
  
  DatabaseService._();
  
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

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
    // Save or update a post and update index
  Future<bool> savePost(PostModel post) async {
    try {
      await _ensureDatabaseInitialized();
      
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

  // Update a post using N1QL
  // Update a post using N1QL
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

  // Get posts count using N1QL
  Future<int> getPostsCount() async {
    try {
      await _ensureDatabaseInitialized();
      
      // Simple count by getting all posts and counting them
      final posts = await getAllPosts();
      return posts.length;
    } catch (e) {
      print('❌ Failed to get posts count: $e');
      return 0;
    }
  }

  // Check if post exists
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
    
    // CouchbaseLite document ID rules:
    // 1. Cannot start with underscore (reserved for system docs)
    // 2. Should be URL-safe characters
    // 3. Cannot be null or empty
    
    String sanitized = originalId.trim();
    
    // If it starts with underscore, prefix with 'doc_'
    if (sanitized.startsWith('_')) {
      sanitized = 'doc$sanitized';
    }
    
    // Replace any problematic characters with underscores
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\-\.]'), '_');
    
    if (sanitized.isEmpty) {
      sanitized = 'post_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return sanitized;
  }

  // Close database connection
  Future<void> close() async {
    try {
      await _database?.close();
      _database = null;
      print('🔒 Database connection closed');
    } catch (e) {
      print('❌ Failed to close database: $e');
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
      // Don't rethrow - index update is not critical for post saving
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
}

class DatabaseException implements Exception {
  final String message;
  
  DatabaseException(this.message);
  
  @override
  String toString() => 'DatabaseException: $message';
}