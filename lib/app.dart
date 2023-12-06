import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pulse_oximter/config/themes/darktheme.dart';
import 'package:pulse_oximter/core/utils/hex_color.dart';
import 'package:pulse_oximter/features/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      darkTheme: darkTheme,
      home: HomeScreen(),
    );
  }
}