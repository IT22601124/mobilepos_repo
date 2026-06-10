import 'package:flutter/material.dart';
import 'package:mpos/main_widget/main_button.dart';
import 'package:mpos/screens/auth_screens/register_screen.dart';

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

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logging in...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.background,
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
                      'Unlock your mobile checkout drawer',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ================= PHONE =================
                  Text(
                    'MOBILE NUMBER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color.onSurface.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: color.onSurface),
                    decoration: InputDecoration(
                      hintText: 'e.g. 0777123456',
                      hintStyle: TextStyle(
                        color: color.onSurface.withOpacity(0.4),
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
                          color: color.outline.withOpacity(0.3),
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
                    'PASSWORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color.onSurface.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: color.onSurface),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(
                        color: color.onSurface.withOpacity(0.4),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) {
                              setState(() => _rememberMe = v ?? false);
                            },
                            activeColor: color.primary,
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(color: color.onSurface),
                          ),
                        ],
                      ),

                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: color.primary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ================= LOGIN BUTTON =================
                  MainButton(text: 'Login', onPressed: _handleLogin,),

                  const SizedBox(height: 20),

                  // ================= SIGN UP =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: color.onSurface.withOpacity(0.6)),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NovaCreateAccountScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: color.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}