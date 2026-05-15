import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData faujiLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.gold, primary: AppColors.gold, background: Colors.white, surface: AppColors.surface, onPrimary: AppColors.onPrimary),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(backgroundColor: AppColors.gold, foregroundColor: AppColors.onPrimary),
);

final ThemeData faujiDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.gold, brightness: Brightness.dark, primary: AppColors.gold, background: AppColors.background, surface: AppColors.surface, onPrimary: AppColors.onPrimary),
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(backgroundColor: AppColors.darkBlue, foregroundColor: AppColors.onPrimary),
);
