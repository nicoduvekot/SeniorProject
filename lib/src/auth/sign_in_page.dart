import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_account_page.dart';
import '../widgets/app_alert.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> signIn() async {
    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException {
      _showError("Invalid Credentials");
    } catch (_) {
      _showError("Something went wrong. Please try again");
    } finally {
      if (mounted) setState (() => isLoading = false);
    }
  }

  void _showError(String message) {
    AppAlert.showConfirm(
        context,
        message,
        title: "Sign-In Error");
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email")
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: canSubmit ? signIn : null,
              child: isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Text("Sign in"),
            ),

            TextButton(
              onPressed: isLoading
                ? null
                : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAccountPage(),
                    ),
                  );
                },
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}