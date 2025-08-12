# Flutter Couchbase Lite Demo App

A high-performance offline-first Flutter application demonstrating Couchbase Lite integration for local storage with full CRUD functionality. This app randomly fetches posts from the JSONPlaceholder API, stores them locally, and allows full offline data manipulation.

## 🚀 Features

### 📥 Fetch Posts Randomly
- Retrieves posts from JSONPlaceholder API.
- Stores them directly into the local Couchbase Lite database.

### 💾 Offline-First Storage
- Powered by Couchbase Lite, ensuring data is available even without an internet connection.

### 🛠 Complete CRUD Support
- Create new posts.
- Read posts from the database.
- Update existing posts.
- Delete posts from local storage.

### 🔄 Easy Refresh
- Pull-to-refresh gesture.
- Dedicated Refresh button for manual updates.

### 📢 Instant Feedback
- Snackbar notifications for every CRUD operation (success or error).

### 📊 Database Statistics
- Shows:
  - Last updated timestamp.
  - Total number of posts in local storage.

## 🛠 Tech Stack

### Framework
- Flutter

### Libraries Used
```yaml
dependencies:
  http: ^1.0.0           # For API calls
  provider: ^6.0.0       # State management
  cbl: 3.5.0             # Core Couchbase Lite
  cbl_flutter: 3.3.2     # Flutter integration for Couchbase Lite
  cbl_flutter_ce: 3.4.0  # Couchbase Lite Community Edition
```

## 📂 Project Structure
```bash
lib/
 ├── main.dart                # App entry point
 ├── models/                  # Data models
 ├── services/                # API + Database services
 ├── providers/               # State management logic
 ├── screens/                 # UI screens (Home, CRUD pages)
 ├── widgets/                 # Reusable UI components
```

## ⚙️ How It Works

### App Launch
- Initializes Couchbase Lite local database.
- Fetches and displays stored posts from local DB.

### Fetching Posts
- Uses `http` package to fetch from JSONPlaceholder API.
- Randomly picks posts and saves them to Couchbase Lite.

### CRUD Operations
- Interacts directly with Couchbase Lite database for all operations.
- Snackbar notifies user about operation status.

### Statistics Display
- Home screen shows database metrics:
  - Total posts.
  - Last updated time.

## 📸 Screenshots
(Add your screenshots here — Pulkit will love visuals!)

## 🏃‍♂️ Getting Started

1. **Clone this repo**
   ```bash
   git clone https://github.com/iamisathya/couchbase_lite.git
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 💡 Why This Demo?
This project demonstrates:
- Offline-first architecture using Couchbase Lite.
- Real-world CRUD implementation in Flutter.
- Integration of remote APIs with local persistent storage.
- Smooth state management and UI/UX feedback.

## 📬 Contact
For any queries or collaborations:
- 📧 [iamisathya@gmail.com](mailto:iamisathya@gmail.com)
- 💼 [LinkedIn](https://www.linkedin.com/in/iamisathya)
