
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ================= WELCOME SCREEN =================

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFCFF),
              Color(0xFFF4E8F8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Column(
              children: [
                const Spacer(),

                Image.asset(
                  'assets/images/lupus_logo.png',
                  height: 180,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Informer • Suivre • Prendre soin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.purple,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),

                const Spacer(),

                _primaryButton(
                  context,
                  'Se connecter',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.purple,
                      side: const BorderSide(
                        color: AppTheme.purple,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Créer un compte'),
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

// ================= LOGIN SCREEN =================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final password = TextEditingController();

  bool remember = true;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Connexion : le service d’authentification sera ajouté prochainement.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connexion',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bienvenue',
                        style: TextStyle(
                          fontSize: 26,
                          color: AppTheme.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Connectez-vous à votre compte',
                        style: TextStyle(
                          color: AppTheme.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 28),

                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'Email',
                        ),
                        validator: _emailValidator,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: password,
                        obscureText: obscure,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: 'Mot de passe',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => obscure = !obscure);
                            },
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir votre mot de passe.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Checkbox(
                            value: remember,
                            activeColor: AppTheme.purple,
                            onChanged: (value) {
                              setState(() {
                                remember = value ?? false;
                              });
                            },
                          ),

                          const Expanded(
                            child: Text(
                              'Se souvenir de moi',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'La récupération du mot de passe sera ajoutée prochainement.',
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      _primaryButton(
                        context,
                        'Se connecter',
                        _login,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text(
                      'Vous n’avez pas de compte ? ',
                      style: TextStyle(fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Inscrivez-vous',
                        style: TextStyle(
                          color: AppTheme.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= SIGNUP SCREEN =================

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final birth = TextEditingController();

  bool obscure = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    birth.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
      helpText: 'Choisir votre date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );

    if (date != null && mounted) {
      setState(() {
        birth.text =
            '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}';
      });
    }
  }

  void _signup() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AccountTypeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Créer un compte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _field(
                        name,
                        'Nom complet',
                        Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir votre nom complet.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _field(
                        email,
                        'Email',
                        Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: password,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: 'Mot de passe',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => obscure = !obscure);
                            },
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir un mot de passe.';
                          }

                          if (value.length < 8) {
                            return '8 caractères minimum.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: confirm,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: 'Confirmer le mot de passe',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscureConfirm = !obscureConfirm;
                              });
                            },
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez confirmer votre mot de passe.';
                          }

                          if (value != password.text) {
                            return 'Les mots de passe ne correspondent pas.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: birth,
                        readOnly: true,
                        onTap: _selectBirthDate,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.calendar_month_outlined,
                          ),
                          hintText: 'Date de naissance  JJ / MM / AAAA',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez choisir votre date de naissance.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 22),

                      _primaryButton(
                        context,
                        'S’inscrire',
                        _signup,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text(
                      'Déjà un compte ? ',
                      style: TextStyle(fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: AppTheme.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= ACCOUNT TYPE SCREEN =================

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  String selected = 'patient';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: AppTheme.purple),
        title: const Text(
          'Type de compte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),

              const Text(
                'Je suis',
                style: TextStyle(
                  color: AppTheme.purple,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _typeTile(
                'patient',
                'Un patient',
                Icons.person,
              ),

              const SizedBox(height: 12),

              _typeTile(
                'proche',
                'Un proche',
                Icons.groups,
              ),

              const Spacer(),

              Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Options avancées'),
                ),
              ),

              _primaryButton(
                context,
                'Suivant',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Type sélectionné : '
                        '${selected == 'patient' ? 'Patient' : 'Proche'}',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeTile(String value, String label, IconData icon) {
    final active = selected == value;

    return InkWell(
      onTap: () {
        setState(() => selected = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EAF6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppTheme.purple
                : Colors.transparent,
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.purple,
              size: 30,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.purple,
            ),
          ],
        ),
      ),
    );
  }
}

// ================= VALIDATION =================

String? _emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Veuillez saisir votre adresse email.';
  }

  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  if (!emailRegex.hasMatch(value.trim())) {
    return 'Veuillez saisir une adresse email valide.';
  }

  return null;
}

// ================= REUSABLE FIELD =================

Widget _field(
  TextEditingController controller,
  String hint,
  IconData icon, {
  bool obscure = false,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      prefixIcon: Icon(icon),
      hintText: hint,
    ),
  );
}

// ================= PRIMARY BUTTON =================

Widget _primaryButton(
  BuildContext context,
  String label,
  VoidCallback onPressed,
) {
  return SizedBox(
    width: double.infinity,
    height: 49,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.purple,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
  );
}
