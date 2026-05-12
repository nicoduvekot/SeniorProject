import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  //Google Sign In Logic
  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      // Trigger system level account picker
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) return;

      // Request scopes to retrieve the Access Token (for Firebase)
      final List<String> scopes = ['email', 'profile'];
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(scopes);

      // Create Firebase Credential using both tokens
      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
        accessToken: clientAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      _showError("Sign-in failed. Check your network or console settings.");
    } finally {
      if (mounted) setState(() => isLoading = false);
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
        child: SingleChildScrollView(
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

              //Standard Email Sign-In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSubmit ? signIn : null,
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Sign in"),
                ),
              ),

              const SizedBox(height: 12),

              //Google Sign-In Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: canSubmit ? signInWithGoogle : null,
                  icon: const Icon(Icons.login),
                  label: const Text("Sign in with Google"),
                ),
              ),

              const SizedBox(height: 20),
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
      ),
    );
  }
}