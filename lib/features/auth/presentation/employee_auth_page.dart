import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/core/router/app_route_guard.dart';
import 'package:hr_portal/core/widgets/app_logo.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/repository_providers.dart';
import 'package:hr_portal/services/auth_service.dart';

class EmployeeAuthPage extends ConsumerStatefulWidget {
  const EmployeeAuthPage({super.key});

  @override
  ConsumerState<EmployeeAuthPage> createState() => _EmployeeAuthPageState();
}

class _EmployeeAuthPageState extends ConsumerState<EmployeeAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final authService = ref.read(authServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        await authService.signUp(email: email, password: password);
      } else {
        await authService.signIn(email: email, password: password);
      }

      final employee = await ref
          .read(employeeRepositoryProvider)
          .getEmployeeByEmail(email);

      if (!mounted) {
        return;
      }

      if (employee == null) {
        await authService.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Your email is not registered. Contact HR to be added to the roster.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 8),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await ref
          .read(employeeAccessSyncServiceProvider)
          .ensureEmailIndexForEmployee(employee);

      ref.invalidate(currentEmployeeProvider);
      if (mounted) {
        final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
        if (redirect == AppRouteGuard.loginHoursRedirect) {
          context.go(AppRoutes.loginHours);
        } else {
          context.go(AppRoutes.attendanceLeaves);
        }
      }
    } on AppException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(subtitle: 'Employee Sign In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ResponsivePadding(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppLogo(size: 72),
                      const SizedBox(height: 24),
                      Text(
                        _isSignUp ? 'Create Account' : 'Employee Sign In',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use your ${AppConstants.allowedEmailDomain} work email.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Sign In')),
                          ButtonSegment(
                            value: true,
                            label: Text('First-time Sign Up'),
                          ),
                        ],
                        selected: {_isSignUp},
                        onSelectionChanged: (selection) {
                          setState(() => _isSignUp = selection.first);
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        decoration: InputDecoration(
                          labelText: 'Work email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          hintText: 'name${AppConstants.allowedEmailDomain}',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!AuthService.isAllowedCompanyEmail(value)) {
                            return 'Use your ${AppConstants.allowedEmailDomain} email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (_isSignUp && value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.business_outlined),
                        label: const Text(
                          'Sign in with Microsoft (coming soon)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
