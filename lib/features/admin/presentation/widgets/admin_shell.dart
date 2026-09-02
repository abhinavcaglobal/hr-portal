import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/core/theme/app_theme.dart';
import 'package:hr_portal/core/widgets/app_logo.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/admin/presentation/admin_nav.dart';
import 'package:hr_portal/features/admin/presentation/widgets/admin_sidebar.dart';
import 'package:hr_portal/providers/admin_auth_providers.dart';
import 'package:hr_portal/providers/admin_providers.dart';
import 'package:hr_portal/providers/auth_providers.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({
    super.key,
    required this.current,
    required this.body,
    this.subtitle = 'Admin Portal',
    this.syncEmployeeAccessOnLoad = false,
  });

  final AdminNavItem current;
  final Widget body;
  final String subtitle;
  final bool syncEmployeeAccessOnLoad;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runInitialSync());
  }

  Future<void> _runInitialSync() async {
    if (!widget.syncEmployeeAccessOnLoad) {
      return;
    }
    final isFirebaseAdmin = ref.read(isHrAdminAccountProvider);
    if (!isFirebaseAdmin) {
      return;
    }
    await ref.read(adminUploadControllerProvider.notifier).syncEmployeeAccess();
  }

  Future<void> _signOut() async {
    await ref.read(adminAuthProvider.notifier).logoutFully();
    ref.invalidate(currentEmployeeProvider);
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final email =
        ref.watch(authStateProvider).valueOrNull?.email ??
        AppConstants.adminEmail;

    final appBar = AppBar(
      title: AppBarTitle(subtitle: widget.subtitle),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 8),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        appBar: appBar,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 248,
              child: AdminSidebar(current: widget.current),
            ),
            Expanded(child: widget.body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: appBar,
      drawer: Drawer(
        backgroundColor: AppTheme.primaryColor,
        child: AdminSidebar(
          current: widget.current,
          onNavigate: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: widget.body,
    );
  }
}
