import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/models/patient.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// Page to create a new appointment.
// Closes with the appointment's date when saved (null if the user goes back).
class NewRdvPage extends StatefulWidget {
  final List<Patient> patients; // patients the doctor can choose from
  final DateTime dateInitiale; // date pre-filled in the form
  final int? patientIdInitial; // patient preselected (e.g. from the patient file)

  const NewRdvPage({
    super.key,
    required this.patients,
    required this.dateInitiale,
    this.patientIdInitial,
  });

  @override
  State<NewRdvPage> createState() => _NewRdvPageState();
}

class _NewRdvPageState extends State<NewRdvPage> {
  final MedecinService _service = MedecinService();
  final _formKey = GlobalKey<FormState>();

  Patient? _patient;
  late DateTime _date;
  TimeOfDay _heure = const TimeOfDay(hour: 9, minute: 0);

  late final TextEditingController _dateCtrl;
  late final TextEditingController _heureCtrl;
  final TextEditingController _lieuCtrl = TextEditingController();
  final TextEditingController _motifCtrl = TextEditingController();

  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _date = widget.dateInitiale;
    // Preselect the patient if one was given.
    if (widget.patientIdInitial != null) {
      for (final p in widget.patients) {
        if (p.id == widget.patientIdInitial) _patient = p;
      }
    }
    _dateCtrl = TextEditingController(text: _formatDate(_date));
    _heureCtrl = TextEditingController(text: _formatHeure(_heure));
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _heureCtrl.dispose();
    _lieuCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  String _formatHeure(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // Opens the calendar popup.
  Future<void> _choisirDate() async {
    final choix = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (choix == null) return;
    setState(() {
      _date = choix;
      _dateCtrl.text = _formatDate(choix);
    });
  }

  // Opens the clock popup.
  Future<void> _choisirHeure() async {
    final choix = await showTimePicker(context: context, initialTime: _heure);
    if (choix == null) return;
    setState(() {
      _heure = choix;
      _heureCtrl.text = _formatHeure(choix);
    });
  }

  String? _obligatoire(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return AppStrings.champObligatoire;
    }
    return null;
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enregistrement = true);

    final dateHeure = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _heure.hour,
      _heure.minute,
    );
    final lieu = _lieuCtrl.text.trim();

    await _service.addRendezVous(
      patient: _patient!,
      dateHeure: dateHeure,
      motif: _motifCtrl.text.trim(),
      lieu: lieu.isEmpty ? null : lieu,
    );

    if (!mounted) return;
    Navigator.pop(context, dateHeure);
  }

  OutlineInputBorder _bordure(Color couleur) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: couleur),
    );
  }

  // Look shared by all the fields (same as the edit profile page).
  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 17, color: AppColors.primary),
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
      focusedBorder: _bordure(AppColors.primary),
      errorBorder: _bordure(AppColors.danger),
      focusedErrorBorder: _bordure(AppColors.danger),
    );
  }

  static const TextStyle _styleSaisie = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // Space under each field.
  Widget _espace(Widget champ) {
    return Padding(padding: const EdgeInsets.only(bottom: 22), child: champ);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.nouveauRdvTitre,
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
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              // Patient choice.
              _espace(
                DropdownButtonFormField<Patient>(
                  initialValue: _patient,
                  isExpanded: true,
                  style: _styleSaisie,
                  decoration: _decoration(
                    AppStrings.patient,
                    Icons.person_outline,
                  ),
                  items: widget.patients
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.nom)))
                      .toList(),
                  onChanged: (valeur) => _patient = valeur,
                  validator: (v) =>
                      v == null ? AppStrings.champObligatoire : null,
                ),
              ),

              // Date (tap opens the calendar).
              _espace(
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _choisirDate,
                  style: _styleSaisie,
                  decoration: _decoration(
                    AppStrings.date,
                    Icons.calendar_today_outlined,
                  ),
                ),
              ),

              // Time (tap opens the clock).
              _espace(
                TextFormField(
                  controller: _heureCtrl,
                  readOnly: true,
                  onTap: _choisirHeure,
                  style: _styleSaisie,
                  decoration: _decoration(
                    AppStrings.heure,
                    Icons.access_time,
                  ),
                ),
              ),

              // Place (optional).
              _espace(
                TextFormField(
                  controller: _lieuCtrl,
                  textInputAction: TextInputAction.next,
                  style: _styleSaisie,
                  decoration: _decoration(
                    AppStrings.lieu,
                    Icons.location_on_outlined,
                  ),
                ),
              ),

              // Reason (required).
              _espace(
                TextFormField(
                  controller: _motifCtrl,
                  validator: _obligatoire,
                  style: _styleSaisie,
                  decoration: _decoration(
                    AppStrings.motif,
                    Icons.description_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              ElevatedButton(
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
                        AppStrings.ajouter,
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