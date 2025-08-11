import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:mindweave/providers/post_provider.dart';
import 'package:mindweave/screens/home_screen.dart';
import 'package:mindweave/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Couchbase Lite for Flutter
  await CouchbaseLiteFlutter.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PostProvider(),
      child: MaterialApp(
        title: 'MindWeave - Post Manager',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
