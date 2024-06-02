import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scrap_saathi/screens/auth_screen.dart';
import 'package:scrap_saathi/screens/home_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAcXgc4lRX932D4UxixHwZzDc5jfbzV7YE",
      authDomain: "scrap-saathi.firebaseapp.com",
      databaseURL:
          "https://scrap-saathi-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "scrap-saathi",
      storageBucket: "scrap-saathi.appspot.com",
      messagingSenderId: "632547078251",
      appId: "1:632547078251:android:74c0465585d9ba5603012e",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return const HomeScreen(selectedIndex: 0);
        }
        return const AuthScreen();
      },
    );
  }
}
