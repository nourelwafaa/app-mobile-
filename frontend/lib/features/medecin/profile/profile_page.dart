import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/name_utils.dart';
import 'package:lupus_plus/features/medecin/profile/widgets/profile_info_row.dart';
import 'package:lupus_plus/models/medecin_profile.dart';
import 'package:lupus_plus/services/medecin_service.dart';
import 'package:lupus_plus/features/medecin/profile/edit_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:lupus_plus/providers/auth_provider.dart';

// The doctor's profile page.
// StatefulWidget because it loads the profile once when it opens.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final MedecinService _service = MedecinService();

  // The profile being loaded (available "in the future").
  late Future<MedecinProfile> _futureProfile;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _photo; // profile photo (null = the initial is shown)

  @override
  void initState() {
    super.initState();
    // Start loading ONCE, when the page opens.
        // The logged-in account (this page only exists when someone is logged in).
    final user = context.read<AuthProvider>().user!;
    _futureProfile = _service.getProfile(user);
    _photo = _service.getPhoto(user);
  }

  @override
  Widget build(BuildContext context) {
    // SafeArea keeps the content away from the phone's status bar.
    return SafeArea(
      child: FutureBuilder<MedecinProfile>(
        future: _futureProfile,
        builder: (context, snapshot) {
          // 1. Still loading: show a spinner.
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Loading failed: show an error message.
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text(AppStrings.erreurChargement));
          }

          // 3. Profile is ready: show the page.
          return _buildContent(snapshot.data!);
        },
      ),
    );
  }

  // Asks "Voulez-vous vous déconnecter ?" and waits for the answer.
  Future<void> _confirmerDeconnexion() async {
    // showDialog returns true or false depending on the button tapped
    // (null if the user taps outside the popup).
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent, // no purple tint on white
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Text(
            AppStrings.deconnexionMessage,
            style: TextStyle(fontSize: 15, color: AppColors.textDark),
          ),
          actions: [
            // "Annuler": closes the popup and returns false.
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                AppStrings.annuler,
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            // "Se déconnecter": closes the popup and returns true.
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                AppStrings.seDeconnecter,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirme == true && mounted) {
      // Deletes the token and the user. AuthGate then shows the Welcome screen.
      await context.read<AuthProvider>().logout();
    }
  }

  // Sheet: take a photo, pick from the gallery, or remove the current one.
  Future<void> _choisirPhoto() async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(AppStrings.prendrePhoto),
                onTap: () => Navigator.pop(sheetContext, 'camera'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(AppStrings.choisirGalerie),
                onTap: () => Navigator.pop(sheetContext, 'galerie'),
              ),
              if (_photo != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    AppStrings.supprimerPhoto,
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'supprimer'),
                ),
            ],
          ),
        );
      },
    );

    if (choix == null || !mounted) return;

    if (choix == 'supprimer') {
      final user = context.read<AuthProvider>().user!;
      _service.setPhoto(user, null);
      setState(() => _photo = null);
      return;
    }

    await _recupererPhoto(
      choix == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
  }

  // Opens the camera or the gallery and keeps the chosen photo.
  Future<void> _recupererPhoto(ImageSource source) async {
    try {
      final fichier = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (fichier == null) return; // cancelled
      final octets = await fichier.readAsBytes();
      if (!mounted) return;

      final user = context.read<AuthProvider>().user!;
      _service.setPhoto(user, octets);
      setState(() => _photo = octets);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.photoErreur)),
      );
    }
  }
  
  // Opens the edit page, then refreshes this page if something was saved.
  Future<void> _modifierProfil(MedecinProfile profil) async {
    // Navigator.push opens the new page and waits until it closes.
    // The page returns true if the profile was saved.
    final modifie = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profil: profil)),
    );

    if (modifie == true && mounted) {
      // Reload the profile so the new values appear.
      final user = context.read<AuthProvider>().user!;
      setState(() {
        // The logged-in account (this page only exists when someone is logged in).
        
        _futureProfile = _service.getProfile(user);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profilMisAJour)),
      );
    }
  }
  // The page content, once the profile is loaded.
  Widget _buildContent(MedecinProfile profil) {
    // ListView = scrollable, so nothing is cut on small screens.
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Page title.
        const Center(
          child: Text(
            AppStrings.monProfil,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Avatar: purple circle with the initial of the name.
        // Avatar: the photo, or a purple circle with the initial. Tap to change.
        Center(
          child: GestureDetector(
            onTap: _choisirPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primary,
                  backgroundImage: _photo == null ? null : MemoryImage(_photo!),
                  child: _photo == null
                      ? Text(
                          initialeNom(profil.nomComplet),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                // Small camera badge at the bottom-right.
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Name with the "Dr" title.
        Center(
          child: Text(
            nomAvecTitre(profil.nomComplet),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.nameText,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle: fixed role text.
        const Center(
          child: Text(
            AppStrings.roleMedecin,
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
        ),
        const SizedBox(height: 20),

        // White card with the 5 information rows.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.iconSquare),
          ),
          child: Column(
            children: [
              ProfileInfoRow(
                icon: Icons.people_outline,
                label: AppStrings.specialite,
                value: profil.specialite,
              ),
              ProfileInfoRow(
                icon: Icons.home_outlined,
                label: AppStrings.etablissement,
                value: profil.etablissement,
              ),
              ProfileInfoRow(
                icon: Icons.location_on_outlined,
                label: AppStrings.adresse,
                value: profil.adresseComplete, // address + city together
              ),
              ProfileInfoRow(
                icon: Icons.mail_outline,
                label: AppStrings.email,
                value: profil.email,
              ),
              ProfileInfoRow(
                icon: Icons.phone_outlined,
                label: AppStrings.telephone,
                value: profil.telephone,
                showDivider: false, // last row: no line below
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // "Modifier mon profil" button.
        ElevatedButton(
          onPressed: () => _modifierProfil(profil),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52), // full width, 52 high
            shape: const StadiumBorder(), // fully rounded ends
            elevation: 0,
          ),
          child: const Text(
            AppStrings.modifierProfil,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),

        // "Se déconnecter" red link.
        Center(
          child: TextButton(
            onPressed: _confirmerDeconnexion,
            child: const Text(
              AppStrings.seDeconnecter,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
        ),
      ],
    );
  }
}