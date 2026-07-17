import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpos/main_widget/main_button.dart';
import 'package:mpos/provider/auth_provider/auth_provider.dart';
import 'package:mpos/utils/app_back_scope.dart';
import 'package:provider/provider.dart';

import '../../model/user_model.dart';

class NovaCreateAccountScreen extends StatefulWidget {
  const NovaCreateAccountScreen({super.key});

  @override
  State<NovaCreateAccountScreen> createState() =>
      _NovaCreateAccountScreenState();
}

class _NovaCreateAccountScreenState extends State<NovaCreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _ownerController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async{
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_formKey.currentState!.validate()) {
      final user = UserModel(
        name: _ownerController.text.trim(),
        phone: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await authProvider.createAccount(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account ready. Sign in to continue.')),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    InputDecoration buildInput(String hint, IconData icon,
        {Widget? suffix}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: color.onSurface.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: color.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: color.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: color.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: color.primary, width: 1.5),
        ),
      );
    }

    return AppBackScope(
      fallbackRoute: '/login',
      child: Scaffold(
      appBar: AppBar(
        title:  Column(
          children: [
            SizedBox(height: 8),
            Center(
              child: Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 6),

          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: color.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("FULL NAME",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color.onSurface.withOpacity(0.6))),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _ownerController,
                  decoration:
                  buildInput("e.g. Alex Mercer", Icons.person),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                Text("MOBILE NUMBER",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color.onSurface.withOpacity(0.6))),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration:
                  buildInput("e.g. 0712345678", Icons.phone_android),
                  validator: (value) {
                    if (value == null || value.trim().length < 9) {
                      return 'Enter valid mobile number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ================= EMAIL =================
                Text("EMAIL ADDRESS",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color.onSurface.withOpacity(0.6))),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                  buildInput("admin@admin.com", Icons.email_outlined),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ================= PASSWORD =================
                Text("TERMINAL PASSWORD",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color.onSurface.withOpacity(0.6))),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: buildInput(
                    "••••••••",
                    Icons.lock_outline,
                    suffix: IconButton(
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
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Use at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ================= CONFIRM PASSWORD =================
                Text("CONFIRM PASSWORD",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color.onSurface.withOpacity(0.6))),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: buildInput(
                    "Verify password",
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: color.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 28),

              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(padding:const EdgeInsetsDirectional.all(12) ,child: 
      Column(
        mainAxisSize:MainAxisSize.min,
        children: [
          Consumer<AuthProvider>(
              builder: (context,authProvider,child)=>
              MainButton(text: "Create Account", onPressed: _register,isLoading: authProvider.isLoading)),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already registered? ",
                style: TextStyle(
                    color: color.onSurface.withOpacity(0.6)),
              ),
              GestureDetector(
                onTap: () {
                  context.go('/login');
                },
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: color.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          )
        ],
      )
      ),
      ),
    );
  }
}
