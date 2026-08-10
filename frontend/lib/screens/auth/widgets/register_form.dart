import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/buttons/custom_button.dart';
import '../../../widgets/inputs/custom_text_field.dart';

import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
  if (fullNameController.text.trim().isEmpty ||
      emailController.text.trim().isEmpty ||
      passwordController.text.isEmpty ||
      confirmPasswordController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please fill all fields"),
      ),
    );
    return;
  }

  if (passwordController.text !=
      confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Passwords do not match"),
      ),
    );
    return;
  }

  try {
    await context.read<AuthProvider>().register(
          name: fullNameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registration Successful"),
      ),
    );

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.dashboard,
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: fullNameController,
          label: "Full Name",
          hintText: "Enter your full name",
          prefixIcon: Icons.person_rounded,
        ),

        const SizedBox(height: AppSpacing.lg),

        CustomTextField(
          controller: emailController,
          label: "Email",
          hintText: "Enter your email",
          prefixIcon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: AppSpacing.lg),

        CustomTextField(
          controller: passwordController,
          label: "Password",
          hintText: "Create a password",
          prefixIcon: Icons.lock_rounded,
          isPassword: true,
        ),

        const SizedBox(height: AppSpacing.lg),

        CustomTextField(
          controller: confirmPasswordController,
          label: "Confirm Password",
          hintText: "Re-enter your password",
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
        ),

        const SizedBox(height: AppSpacing.xl),

        CustomButton(
          text: "Create Account",
          icon: Icons.person_add_alt_1_rounded,
          isLoading: isLoading,
          onPressed: register,
        ),

        const SizedBox(height: AppSpacing.lg),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Already have an account?",
              style: TextStyle(color: Colors.white70),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Sign In"),
            ),
          ],
        ),
      ],
    );
  }
}