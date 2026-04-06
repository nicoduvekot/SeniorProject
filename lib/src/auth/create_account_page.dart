import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/documents_home_page.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isEmailValid = false;
  bool isPasswordValid = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_validate);
    passwordController.addListener(_validate);
  }

  void _validate() {
    setState(() {
      isEmailValid = RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(emailController.text.trim());
      isPasswordValid = passwordController.text.trim().length >= 6;
    });
  }

  Future<void> register() async {
    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account Successfully created")),
      );

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DocumentsHomePage()),
          (_) => false,
      );

    } on FirebaseAuthException {
      _showError("Invalid Credentials");
    } catch (_) {
      _showError("Something went wrong. Please try again");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = isEmailValid && isPasswordValid && !isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                errorText: isEmailValid ? null : "Enter a valid email",
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                errorText: isPasswordValid ? null : "Min 6 characters required",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: canSubmit ? register : null,
              child: isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Text("Create Account"),
            )
          ]
        )
      )
    );
  }
}