import 'package:flutter/material.dart';
import 'package:leaf_mobile/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //main de la aplicación
  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      home: Scaffold(backgroundColor: Colors.white, body: LoginScreen()),
    );
  }
}
