import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/models/medecin_profile.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// Turns an empty text into null, so the profile shows "Non renseigné".
String? _valeurOuNull(String texte) {
  final propre = texte.trim();
  return propre.isEmpty ? null : propre;
}

// The page where the doctor edits his profile.
class EditProfilePage extends StatefulWidget {
  final MedecinProfile profil; // current profile, used to pre-fill the form

  const EditProfilePage({super.key, required this.profil});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final MedecinService _service = MedecinService();

  // Key used to check ALL the fields at once (validation).
  final _formKey = GlobalKey<FormState>();

  // One controller per field: it holds and reads the typed text.
  late final TextEditingController _nomCtrl;
  late final TextEditingController _specialiteCtrl;
  late final TextEditingController _etablissementCtrl;
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _villeCtrl;
  late final TextEditingController _telephoneCtrl;

  // true while saving: disables the button and shows a spinner.
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill each field with the current value ('' if empty).
    final p = widget.profil;
    _nomCtrl = TextEditingController(text: p.nomComplet);
    _specialiteCtrl = TextEditingController(text: p.specialite ?? '');
    _etablissementCtrl = TextEditingController(text: p.etablissement ?? '');
    _adresseCtrl = TextEditingController(text: p.adresse ?? '');
    _villeCtrl = TextEditingController(text: p.ville ?? '');
    _telephoneCtrl = TextEditingController(text: p.telephone ?? '');
  }

  @override
  void dispose() {
    // Frees the memory used by the controllers.
    _nomCtrl.dispose();
    _specialiteCtrl.dispose();
    _etablissementCtrl.dispose();
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _telephoneCtrl.dispose();
    super.dispose();
  }

  // Validation: the name is required.
  String? _validerNom(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return AppStrings.champObligatoire;
    }
    return null;
  }

  // Validation: the phone is optional, but if filled it needs 8+ digits.
  String? _validerTelephone(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) return null;
    final chiffres = valeur.replaceAll(RegExp(r'\D'), ''); // keeps only digits
    return chiffres.length < 8 ? AppStrings.numeroInvalide : null;
  }

  // Called when the "Enregistrer" button is tapped.
  Future<void> _enregistrer() async {
    // Stop here if a field is invalid (errors appear under the fields).
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enregistrement = true);

    final nouveauProfil = MedecinProfile(
      nomComplet: _nomCtrl.text.trim(),
      specialite: _valeurOuNull(_specialiteCtrl.text),
      etablissement: _valeurOuNull(_etablissementCtrl.text),
      adresse: _valeurOuNull(_adresseCtrl.text),
      ville: _valeurOuNull(_villeCtrl.text),
      email: widget.profil.email, // the email is never changed here
      telephone: _valeurOuNull(_telephoneCtrl.text),
    );

    await _service.updateProfile(nouveauProfil);

    // The page may have been closed while waiting.
    if (!mounted) return;

    // Go back to the profile page and tell it that something changed.
    Navigator.pop(context, true);
  }

  // Border of a field, with the color given.
  OutlineInputBorder _bordure(Color couleur) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: couleur),
    );
  }

  // Look shared by all the fields (white, rounded, icon on the left).
  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      // Label color and size (when it sits inside the field).
      labelStyle: const TextStyle(
        fontSize: 17,
        color: AppColors.primary,
      ),
      // Same look when the label floats on the border.
      floatingLabelStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.card,
      border: _bordure(AppColors.iconSquare),
      enabledBorder: _bordure(AppColors.iconSquare),
      disabledBorder: _bordure(AppColors.iconSquare),
      focusedBorder: _bordure(AppColors.primary),
      errorBorder: _bordure(AppColors.danger),
      focusedErrorBorder: _bordure(AppColors.danger),
    );
  }

  // One text field with some space under it.
  Widget _champ({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next, // "next" key on the keyboard
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        decoration: _decoration(label, icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar: back arrow (automatic) + centered title.
      appBar: AppBar(
        title: const Text(
          AppStrings.modifierProfil,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary), // arrow color
      ),
      body: SafeArea(
        // Form groups the fields so they can be validated together.
        child: Form(
          key: _formKey,
          // ListView scrolls when the keyboard hides part of the form.
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              _champ(
                controller: _nomCtrl,
                label: AppStrings.nomComplet,
                icon: Icons.person_outline,
                validator: _validerNom,
              ),
              _champ(
                controller: _specialiteCtrl,
                label: AppStrings.specialite,
                icon: Icons.people_outline,
              ),
              _champ(
                controller: _etablissementCtrl,
                label: AppStrings.etablissement,
                icon: Icons.home_outlined,
              ),
              _champ(
                controller: _adresseCtrl,
                label: AppStrings.adresse,
                icon: Icons.location_on_outlined,
              ),
              _champ(
                controller: _villeCtrl,
                label: AppStrings.ville,
                icon: Icons.location_city_outlined,
              ),

              // Email: shown but locked (it is the login identifier).
              Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: TextFormField(
                  initialValue: widget.profil.email,
                  enabled: false,
                  style: const TextStyle(fontSize: 16, color: AppColors.textGrey),
                  decoration: _decoration(AppStrings.email, Icons.mail_outline)
                      .copyWith(
                    helperText: AppStrings.emailNonModifiable,
                    // Light red note under the field.
                    helperStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.dangerLight,
                    ),  
                  ),
                ),
              ),

              _champ(
                controller: _telephoneCtrl,
                label: AppStrings.telephone,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone, // numeric keyboard
                validator: _validerTelephone,
              ),
              const SizedBox(height: 6),

              // "Enregistrer" button (same style as "Modifier mon profil").
              ElevatedButton(
                // null disables the button while saving.
                onPressed: _enregistrement ? null : _enregistrer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _enregistrement
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        AppStrings.enregistrer,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}