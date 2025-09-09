import 'package:flutter/material.dart';

// Seed color for Material 3 schemes
const Color seedColor = Color(0xFF64FFDA);

final ColorScheme lightColorScheme =
    ColorScheme.fromSeed(seedColor: seedColor);

final ColorScheme darkColorScheme =
    ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark);

