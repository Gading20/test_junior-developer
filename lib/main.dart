import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // ProviderScope holds every Riverpod provider for the whole app.
  runApp(const ProviderScope(child: ElearningApp()));
}

class ElearningApp extends ConsumerWidget {
  const ElearningApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching here means a test can swap appRouterProvider easily.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'E-Learning',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
