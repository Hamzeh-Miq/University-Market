import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the app-wide [ThemeMode].
///
/// Toggle between light and dark by calling:
/// ```dart
/// ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
/// ```
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
