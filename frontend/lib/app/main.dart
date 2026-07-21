import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../shared/app_shell.dart';
import '../shared/workspace_scope.dart';
import 'router.dart';

void main() {
  runApp(const ConstructionApp());
}

class ConstructionApp extends StatelessWidget {
  const ConstructionApp({super.key});

  @override
  Widget build(BuildContext context) {
    const baseScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0F4C5C),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF2C7A7B),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFB42318),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFF7F8FA),
      onSurface: Color(0xFF111827),
      surfaceContainerHighest: Color(0xFFE7EBF0),
      onSurfaceVariant: Color(0xFF4B5563),
      outline: Color(0xFFD0D5DD),
      outlineVariant: Color(0xFFE4E7EC),
      primaryContainer: Color(0xFFD2ECF2),
      onPrimaryContainer: Color(0xFF0B3340),
      secondaryContainer: Color(0xFFD9F2F0),
      onSecondaryContainer: Color(0xFF123738),
      tertiary: Color(0xFFF79009),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFFFE8C2),
      onTertiaryContainer: Color(0xFF4D3200),
      inverseSurface: Color(0xFF1F2937),
      onInverseSurface: Color(0xFFF9FAFB),
      inversePrimary: Color(0xFF8FD2E0),
      shadow: Color(0x26000000),
      scrim: Color(0x59000000),
      surfaceTint: Color(0xFF0F4C5C),
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.4),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15, height: 1.45),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0F4C5C), width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
        backgroundColor: const Color(0xFFEAF2F4),
        labelStyle: const TextStyle(color: Color(0xFF0F4C5C), fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF0F4C5C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Construction Management',
      theme: theme,
      initialRoute: AppRoutes.dashboard,
      routes: appRoutes.routes,
      builder: (context, child) {
        return WorkspaceScope(
          controller: WorkspaceController.instance,
          child: child ?? const SizedBox.shrink(),
        );
      },
      onUnknownRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => const AppShell(
          title: 'Dashboard',
          currentRoute: AppRoutes.dashboard,
          child: DashboardScreen(),
        ),
      ),
    );
  }
}
