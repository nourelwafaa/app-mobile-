import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'account_type_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _tel = TextEditingController();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  final _date = TextEditingController();
  DateTime? _birth;
  bool _hide = true;

  @override
  void dispose() {
    for (final c in [_nom, _email, _tel, _pwd, _pwd2, _date]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birth = picked;
        _date.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    final draft = RegisterDraft(
      nomComplet: _nom.text,
      email: _email.text,
      telephone: _tel.text,
      motDePasse: _pwd.text,
      // format attendu par le backend / PostgreSQL : AAAA-MM-JJ
      dateNaissance:
          _birth == null ? null : DateFormat('yyyy-MM-dd').format(_birth!),
    );
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => AccountTypeScreen(draft: draft)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppField(
                  label: 'Nom complet',
                  hint: 'Sarah Benali',
                  icon: Icons.person_outline,
                  controller: _nom,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Le nom est obligatoire'
                      : null,
                ),
                AppField(
                  label: 'Email',
                  hint: 'exemple@mail.com',
                  icon: Icons.mail_outline,
                  controller: _email,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "L'email est obligatoire";
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(v.trim())) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                AppField(
                  label: 'Téléphone (optionnel)',
                  hint: '05 55 12 34 56',
                  icon: Icons.phone_outlined,
                  controller: _tel,
                  keyboard: TextInputType.phone,
                ),
                AppField(
                  label: 'Mot de passe',
                  hint: '6 caractères minimum',
                  icon: Icons.lock_outline,
                  controller: _pwd,
                  obscure: _hide,
                  suffix: IconButton(
                    icon: Icon(_hide ? Icons.visibility_off : Icons.visibility,
                        size: 18),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Au moins 6 caractères'
                      : null,
                ),
                AppField(
                  label: 'Confirmer le mot de passe',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  controller: _pwd2,
                  obscure: _hide,
                  validator: (v) => v != _pwd.text
                      ? 'Les mots de passe sont différents'
                      : null,
                ),
                AppField(
                  label: 'Date de naissance',
                  hint: 'JJ / MM / AAAA',
                  icon: Icons.calendar_today_outlined,
                  controller: _date,
                  readOnly: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                PrimaryButton(label: "S'inscrire", onPressed: _next),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text.rich(TextSpan(
                    text: 'Déjà un compte ? ',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                    children: [
                      TextSpan(
                          text: 'Se connecter',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
