import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'add_info_screen.dart';

class AccountTypeScreen extends StatefulWidget {
  final RegisterDraft draft;
  const AccountTypeScreen({super.key, required this.draft});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  String _role = 'patient'; // valeurs attendues par le backend : patient | medecin
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().register(widget.draft, role: _role);
      if (!mounted) return;
      if (_role == 'patient') {
        // Écran "Ajouter des informations" (puis retour à l'écran racine)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => const AddInfoScreen(onboarding: true)),
          (r) => r.isFirst,
        );
      } else {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _option(String role, IconData icon, String title, String subtitle) {
    final selected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.soft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: selected ? AppColors.primary : AppColors.muted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Type de compte')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Je suis',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(height: 16),
              _option('patient', Icons.person, 'Un patient',
                  'Je suis atteint(e) de lupus'),
              _option('medecin', Icons.medical_services, 'Un médecin',
                  'Je suis mes patients'),
              const Spacer(),
              PrimaryButton(
                  label: 'Suivant', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
