import 'package:mpos/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpos/utils/custom_snackbar.dart';
import 'package:mpos/main_widget/main_button.dart';
import 'package:mpos/provider/auth_provider/auth_provider.dart';
import 'package:mpos/utils/app_back_scope.dart';
import 'package:provider/provider.dart';

class NovaLoginScreen extends StatefulWidget {
  const NovaLoginScreen({super.key});

  @override
  State<NovaLoginScreen> createState() => _NovaLoginScreenState();
}

class _NovaLoginScreenState extends State<NovaLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        final provider = Provider.of<AuthProvider>(context, listen: false);
        final success = await provider.login(
          _phoneController.text.trim(),
          _passwordController.text.trim(),
        );
        if (!success) {
          throw context.tr('login_failed');
        }
        if (!mounted) return;
        CustomSnackBar.success(context, context.tr('login_success'));
        context.go('/mainNavigation');
      } catch (e) {
        if (!mounted) return;
        // Strip "Exception: " if present
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.replaceFirst('Exception: ', '');
        }
        CustomSnackBar.error(context, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return AppBackScope(
      allowSystemPop: true,
      child: Scaffold(
      backgroundColor: color.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'NOVA',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: color.onSurface,
                          letterSpacing: 4,
                        ),
                        children: [
                          TextSpan(
                            text: 'POS',
                            style: TextStyle(color: color.primary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Center(
                    child: Text(
                      context.tr('welcome_back'),
                      style: TextStyle(
                        fontSize: 12,
                        color: color.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                   const SizedBox(height: 8),
                  // Center(
                  //   child: Text(
                  //     'Demo: 0777123456 / 123456',
                  //     style: TextStyle(
                  //       fontSize: 12,
                  //       color: color.primary,
                  //       fontWeight: FontWeight.w700,
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 36),

                  // ================= PHONE =================
                  Text(
                    context.tr('mobile_number'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color.onSurface.withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: color.onSurface),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.tr('mobile_number_required');
                      }
                      if (value.trim().length < 9) {
                        return context.tr('valid_mobile_required');
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. 0777123456',
                      hintStyle: TextStyle(
                        color: color.onSurface.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.phone_android_outlined,
                        color: color.primary,
                      ),
                      filled: true,
                      fillColor: color.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: color.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: color.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= PASSWORD =================
                  Text(
                    context.tr('password').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color.onSurface.withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: color.onSurface),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('password_required');
                      }
                      if (value.length < 4) {
                        return context.tr('password_too_short');
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(
                        color: color.onSurface.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: color.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: color.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: color.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= REMEMBER + FORGOT =================
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Row(
                  //       children: [
                  //         Checkbox(
                  //           value: _rememberMe,
                  //           onChanged: (v) {
                  //             setState(() => _rememberMe = v ?? false);
                  //           },
                  //           activeColor: color.primary,
                  //         ),
                  //         Text(
                  //           context.tr('remember_me'),
                  //           style: TextStyle(color: color.onSurface),
                  //         ),
                  //       ],
                  //     ),
                  //
                  //     TextButton(
                  //       onPressed: () {},
                  //       child: Text(
                  //         context.tr('forgot_password'),
                  //         style: TextStyle(color: color.primary),
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  const SizedBox(height: 36),

                  Consumer<AuthProvider>(
                    builder: (context, provider, child) {
                      return MainButton(
                        text: context.tr('login'),
                        onPressed: provider.isLoading ? null : _handleLogin,
                        isLoading: provider.isLoading,
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Text(
                  //       context.tr('dont_have_account'),
                  //       style: TextStyle(
                  //         color: color.onSurface.withValues(alpha: 0.6),
                  //       ),
                  //     ),
                  //     TextButton(
                  //       onPressed: () => context.go('/register'),
                  //       child: Text(context.tr('sign_up')),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
