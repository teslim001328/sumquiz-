import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  double _fontScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale;
    notifyListeners();
  }

  ThemeData _applyFontScaling(ThemeData theme) {
    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        headlineSmall: theme.textTheme.headlineSmall
            ?.copyWith(fontSize: 24.0 * _fontScale),
        headlineMedium: theme.textTheme.headlineMedium
            ?.copyWith(fontSize: 28.0 * _fontScale),
        titleLarge:
            theme.textTheme.titleLarge?.copyWith(fontSize: 22.0 * _fontScale),
        bodyMedium:
            theme.textTheme.bodyMedium?.copyWith(fontSize: 14.0 * _fontScale),
        bodySmall:
            theme.textTheme.bodySmall?.copyWith(fontSize: 12.0 * _fontScale),
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          fontSize: 20.0 * _fontScale,
        ),
      ),
    );
  }

  ThemeData getTheme() {
    final theme = _themeMode == ThemeMode.light ? lightTheme : darkTheme;
    return _applyFontScaling(theme);
  }

  static final ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    ),
    textTheme: ThemeData.light().textTheme.copyWith(
          headlineSmall: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          bodyMedium: const TextStyle(color: AppColors.textPrimary),
          bodySmall: const TextStyle(color: AppColors.textSecondary),
        ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.textSecondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.secondary, width: 2),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    ),
    textTheme: ThemeData.light().textTheme.copyWith(
          headlineSmall: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          bodyMedium: const TextStyle(color: AppColors.textPrimary),
          bodySmall: const TextStyle(color: AppColors.textSecondary),
        ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.textSecondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.secondary, width: 2),
      ),
    ),
  );
}
