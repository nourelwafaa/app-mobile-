import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../auth/add_info_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().loadProfile();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _row(String label, String? value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            Text(value == null || value.isEmpty ? '—' : value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = auth.profile;
    final u = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (u?.nomComplet.isNotEmpty ?? false)
                        ? u!.nomComplet[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 28, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(u?.nomComplet ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 20),
              if (_loading && p == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                SectionCard(
                  child: Column(children: [
                    _row('Email', u?.email),
                    _row('Téléphone', u?.telephone),
                    _row('Date de naissance', u?.dateNaissance),
                    _row('Âge', p?.age == null ? null : '${p!.age} ans'),
                    _row('Sexe', p?.sexe == null ? null : cap(p!.sexe!)),
                    _row('Poids', p?.poids == null ? null : '${p!.poids} kg'),
                    _row('Taille',
                        p?.taille == null ? null : '${p!.taille} cm'),
                    _row('Groupe sanguin', p?.groupeSanguin),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Modifier mes informations',
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddInfoScreen()));
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Se déconnecter',
                onPressed: () => context.read<AuthProvider>().logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
