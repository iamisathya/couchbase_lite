# MindWeave App Architecture

## Overview
A Flutter app that fetches random posts from JSONPlaceholder API, allows editing, and stores posts in CouchbaseLite database with N1QL queries for CRUD operations.

## Core Features
1. **Fetch & Edit Posts**: Get random posts from API and edit title/body
2. **Refresh & Save**: Refresh current post or save to CouchbaseLite
3. **Persistent Storage**: CouchbaseLite database with N1QL queries
4. **List Management**: View, update, delete saved posts
5. **Navigation**: Bottom navigation between Home and List screens
6. **Notifications**: SnackBar feedback for all CRUD operations

## Technical Architecture

### Dependencies
- `couchbase_lite_dart`: CouchbaseLite database integration
- `http`: HTTP client for API calls
- `provider`: State management
- Existing: `google_fonts`, `cupertino_icons`

### File Structure
```
lib/
├── main.dart              # App entry point
├── theme.dart             # Updated theme with button styles
├── models/
│   └── post_model.dart    # Post data model
├── services/
│   ├── api_service.dart   # JSONPlaceholder API service
│   └── database_service.dart  # CouchbaseLite N1QL operations
├── providers/
│   └── post_provider.dart # State management for posts
├── screens/
│   ├── home_screen.dart   # Main screen with fetch/edit
│   ├── post_list_screen.dart  # Saved posts list
│   └── edit_post_screen.dart  # Edit post screen
├── widgets/
│   ├── post_card.dart     # Reusable post display card
│   ├── action_button.dart # Custom action buttons
│   └── loading_widget.dart # Loading indicator
└── utils/
    └── snackbar_helper.dart # SnackBar utilities
```

### Core Components

#### 1. Models
- **PostModel**: Data structure for posts (id, userId, title, body)
- JSON serialization/deserialization methods
- CouchbaseLite document mapping

#### 2. Services
- **ApiService**: Fetch random posts from JSONPlaceholder
- **DatabaseService**: CouchbaseLite operations using N1QL
  - Initialize database
  - CRUD operations with N1QL queries
  - Document management

#### 3. State Management
- **PostProvider**: Manages app state
  - Current displayed post
  - Saved posts list
  - Loading states
  - Error handling

#### 4. UI Screens
- **HomeScreen**: Main interface with bottom navigation
  - Random post display and editing
  - Refresh and Save buttons
- **PostListScreen**: Display saved posts
  - List view with edit/delete actions
- **EditPostScreen**: Edit post details
  - Form validation and save

#### 5. Widgets
- **PostCard**: Reusable post display component
- **ActionButton**: Styled buttons following theme
- **LoadingWidget**: Consistent loading indicators

### Database Schema
- Collection: `posts`
- Document structure:
```json
{
  "type": "post",
  "id": "string",
  "userId": "number", 
  "title": "string",
  "body": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### N1QL Queries
- **Insert**: `INSERT INTO posts VALUES (...)`
- **Select All**: `SELECT * FROM posts WHERE type = "post"`
- **Update**: `UPDATE posts SET ... WHERE id = ?`
- **Delete**: `DELETE FROM posts WHERE id = ?`

## Implementation Steps
1. Add dependencies and update theme
2. Create data models and services
3. Implement database service with N1QL queries
4. Build state management provider
5. Create UI screens and widgets
6. Implement navigation and routing
7. Add error handling and notifications
8. Test and debug complete flow
9. Compile and validate project

## Design Guidelines
- Material 3 design with existing purple theme
- Card-based layouts with rounded corners
- Modern animations and transitions
- Consistent spacing and typography
- High contrast icons and text in buttons
- SnackBar notifications for user feedback