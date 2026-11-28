import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
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

  // Photo de profil (stockée localement pour l'instant)
  // TODO : envoyer la photo au backend (colonne users.photo) quand la route existera
  final _picker = ImagePicker();
  final _storage = const FlutterSecureStorage();
  Uint8List? _photo;

  String get _photoKey => 'photo_${context.read<AuthProvider>().user?.id}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadPhoto();
    });
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

  Future<void> _loadPhoto() async {
    try {
      final b64 = await _storage.read(key: _photoKey);
      if (b64 != null && mounted) setState(() => _photo = base64Decode(b64));
    } catch (_) {}
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final key = _photoKey;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = bytes);
      try {
        await _storage.write(key: key, value: base64Encode(bytes));
      } catch (_) {}
      if (mounted) showSnack(context, 'Photo de profil mise à jour');
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Impossible de charger la photo', error: true);
      }
    }
  }

  Future<void> _removePhoto() async {
    final key = _photoKey;
    setState(() => _photo = null);
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Supprimer la photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Demande une confirmation avant de déconnecter le patient
  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<AuthProvider>().logout();
    }
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
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary,
                        backgroundImage:
                            _photo != null ? MemoryImage(_photo!) : null,
                        child: _photo == null
                            ? Text(
                                (u?.nomComplet.isNotEmpty ?? false)
                                    ? u!.nomComplet[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 30, color: Colors.white),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.soft,
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(u?.nomComplet ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              Center(
                child: TextButton(
                  onPressed: _showPhotoOptions,
                  child: const Text('Modifier la photo',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 10),
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
                onPressed: _confirmLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
