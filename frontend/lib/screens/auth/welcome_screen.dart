import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset('assets/images/lupus_logo.png', width: 110),
              const SizedBox(height: 12),
              const Text('Lupus+',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(height: 6),
              const Text('Informer · Suivre · Prendre soin',
                  style: TextStyle(fontSize: 12, color: AppColors.primary)),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'Se connecter',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Créer un compte',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
