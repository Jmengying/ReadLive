import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/init/app_init.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/book_source/presentation/book_source_provider.dart';
import 'features/settings/presentation/settings_provider.dart';

class ReadLiveApp extends ConsumerStatefulWidget {
  const ReadLiveApp({super.key});

  @override
  ConsumerState<ReadLiveApp> createState() => _ReadLiveAppState();
}

class _ReadLiveAppState extends ConsumerState<ReadLiveApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure widget tree and providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    try {
      final repo = ref.read(bookSourceRepositoryProvider);
      await AppInit.loadBuiltInSources(repo);
    } catch (e) {
      debugPrint('AppInit error: $e');
    }
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return MaterialApp.router(
      title: 'ReadLive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(accentColor),
      darkTheme: AppTheme.darkTheme(accentColor),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
