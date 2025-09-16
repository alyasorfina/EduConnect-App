import 'package:educonnect/login_screen.dart';
import 'package:flutter/material.dart';

class EduConnectApp extends StatelessWidget {
  const EduConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'EduConnect',
      home: LoginScreen(),
    );
  }
}
