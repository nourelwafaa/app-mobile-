import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pwd = TextEditingController();
  bool _remember = true;
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    _id.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(
            identifiant: _id.text,
            motDePasse: _pwd.text,
            remember: _remember,
          );
      if (!mounted) return;
      // AuthGate (écran racine) affiche l'espace adapté au rôle
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bienvenue',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                const Text('Connectez-vous à votre compte',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 24),
                AppField(
                  label: 'Email ou téléphone',
                  hint: 'exemple@mail.com',
                  icon: Icons.mail_outline,
                  controller: _id,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Champ obligatoire'
                      : null,
                ),
                AppField(
                  label: 'Mot de passe',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  controller: _pwd,
                  obscure: _hide,
                  suffix: IconButton(
                    icon: Icon(_hide ? Icons.visibility_off : Icons.visibility,
                        size: 18),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _remember,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _remember = v ?? true),
                    ),
                    const Text('Se souvenir de moi',
                        style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    // Pas de route "mot de passe oublié" dans le backend pour l'instant
                    GestureDetector(
                      onTap: () => showSnack(
                          context, 'Fonction bientôt disponible'),
                      child: const Text('Mot de passe oublié ?',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                    label: 'Se connecter', loading: _loading, onPressed: _submit),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text.rich(TextSpan(
                      text: "Vous n'avez pas de compte ? ",
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                      children: [
                        TextSpan(
                            text: 'Inscrivez-vous',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ],
                    )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
