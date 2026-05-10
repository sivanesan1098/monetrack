import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetrack/core/router/app_router.dart';
import 'package:monetrack/core/theme/app_theme.dart';
import 'package:monetrack/presentation/providers/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetrack/core/services/auto_import_service.dart';
import 'package:monetrack/core/services/background_service.dart'; // Assuming initializeBackgroundService is here or globally available

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundService();
  final container = ProviderContainer();
  globalAutoImportService = AutoImportService(container); 
  runApp(UncontrolledProviderScope(container: container, child: const MonetrackApp()));
}

class MonetrackApp extends ConsumerWidget {
  const MonetrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize AutoImportService
    ref.watch(autoImportServiceProvider);
    
    final router = ref.watch(goRouterProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);

    return settingsAsync.when(
      data: (settings) {
        final themeModeStr = settings['themeMode'] as String;
        final themeMode = themeModeStr == 'light' 
            ? ThemeMode.light 
            : themeModeStr == 'dark' 
                ? ThemeMode.dark 
                : ThemeMode.system;

        return MaterialApp.router(
          title: 'Monetrack',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
      loading: () => const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
      error: (err, stack) => MaterialApp(home: Scaffold(body: Center(child: Text('Error: $err')))),
    );
  }
}
