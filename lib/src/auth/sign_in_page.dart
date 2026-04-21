import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'create_account_page.dart';

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

  //Google Sign-In Logic
  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);

    try {
      // 1. You MUST initialize the instance first in v7.x
      await GoogleSignIn.instance.initialize();

      // 2. Use 'authenticate()' instead of 'signIn()'
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      // 3. Obtain authentication details (idToken is here)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 4. Create the Firebase credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: null,
      );

      // 5. Sign in to Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

    } on GoogleSignInException catch (e) {
      _showError("Sign-in error: ${e.code.name}");
    } catch (e) {
      _showError("Something went wrong. Please try again.");
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