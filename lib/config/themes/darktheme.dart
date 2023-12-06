import 'package:flutter/material.dart';

import '../../core/utils/hex_color.dart';

ThemeData darkTheme = ThemeData(
        colorScheme: ColorScheme.dark(),
        primaryColor:HexColor("1ddba6") ,
        appBarTheme: AppBarTheme(
          backgroundColor: HexColor("1ddba6"),
          foregroundColor: Colors.black87
        ),

      );