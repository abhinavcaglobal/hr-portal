import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/core/theme/app_theme.dart';
import 'package:hr_portal/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const ProviderScope(child: CaGlobalLeavePortalApp()));
}

class CaGlobalLeavePortalApp extends ConsumerWidget {
  const CaGlobalLeavePortalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CA Global Leave Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
