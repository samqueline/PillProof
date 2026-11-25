import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/medical_mesh_background.dart';
import '../../../../shared/widgets/pill_proof_logo.dart';
import '../../../../shared/widgets/pill_text_field.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/pillwise_floating_button.dart';
import '../auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Email ID or Mobile Number')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    // Call auth controller
    final success = await ref
        .read(authControllerProvider.notifier)
        .login(identifier, password);

    if (mounted) {
      if (success) {
        context.go('/dashboard');
      } else {
        // If credentials fail in demo mode, allow direct entry to dashboard
        final error = ref.read(authControllerProvider).errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              action: SnackBarAction(
                label: 'Enter Demo',
                textColor: Colors.amberAccent,
                onPressed: () => context.go('/dashboard'),
              ),
            ),
          );
        } else {
          context.go('/dashboard');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: MedicalMeshBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),

                          // 1. PillProof Shield Logo & Tagline (Image 1)
                          const PillProofLogoWidget(size: 210),

                          const SizedBox(height: 38),

                          // 2. Field 1: Enter Email ID or Mobile Number
                          PillTextField(
                            controller: _identifierController,
                            hintText: 'Enter Email ID or Mobile Number',
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 16),

                          // 3. Field 2: Enter Password
                          PillTextField(
                            controller: _passwordController,
                            hintText: 'Enter Password',
                            obscureText: true,
                          ),

                          const SizedBox(height: 26),

                          // 4. Primary Button: LOGIN with purple neon edge
                          PillButton(
                            label: 'LOGIN',
                            isLoading: authState.isLoading,
                            onPressed: _handleLogin,
                          ),

                          const SizedBox(height: 18),

                          // 5. Navigation Links
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset instructions sent to your email.'),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF01579B), // Dark Navy Blue
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Center(
                            child: GestureDetector(
                              onTap: () => context.go('/signup'),
                              child: const Text(
                                'Create an account',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF01579B), // Dark Navy Blue
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 60), // Room for bottom widget
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom-right floating PILLWISE button
            const PillwiseFloatingButton(),
          ],
        ),
      ),
    );
  }
}
