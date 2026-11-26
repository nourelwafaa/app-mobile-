import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/theme/form_style.dart';
import 'package:lupus_plus/providers/auth_provider.dart';
import 'package:lupus_plus/services/traitement_service.dart';

// Form to add a medication to a patient. Closes with true when saved.
// Médecin : AddTraitementPage(patientId: ...) → POST /api/medecin/patients/:id/traitements.
// Patient : AddTraitementPage.patient() → POST /api/patients/me/traitements.
class AddTraitementPage extends StatefulWidget {
  final int? patientId; // null = le patient connecté ajoute son médicament

  const AddTraitementPage({super.key, required int this.patientId});

  const AddTraitementPage.patient({super.key}) : patientId = null;

  @override
  State<AddTraitementPage> createState() => _AddTraitementPageState();
}

class _AddTraitementPageState extends State<AddTraitementPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _debutCtrl = TextEditingController();
  final _finCtrl = TextEditingController();

  int _fois = 1;
  late DateTime _debut;
  DateTime? _fin; // optional

  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _debut = DateTime(n.year, n.month, n.day);
    _debutCtrl.text = _format(_debut);
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _dosageCtrl.dispose();
    _debutCtrl.dispose();
    _finCtrl.dispose();
    super.dispose();
  }

  String _format(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<void> _choisirDebut() async {
    final choix = await showDatePicker(
      context: context,
      initialDate: _debut,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (choix == null) return;
    setState(() {
      _debut = choix;
      _debutCtrl.text = _format(choix);
    });
  }

  Future<void> _choisirFin() async {
    final choix = await showDatePicker(
      context: context,
      initialDate: _fin ?? _debut,
      firstDate: _debut,
      lastDate: DateTime(2100),
    );
    if (choix == null) return;
    setState(() {
      _fin = choix;
      _finCtrl.text = _format(choix);
    });
  }

  String? _obligatoire(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.champObligatoire;
    return null;
  }

  // The end date must not be before the start date.
  String? _validerFin(String? _) {
    if (_fin != null && _fin!.isBefore(_debut)) return AppStrings.finAvantDebut;
    return null;
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enregistrement = true);

    try {
      final patientId = widget.patientId;
      final service = TraitementService(context.read<AuthProvider>().api);
      if (patientId == null) {
        // Patient connecté : POST /api/patients/me/traitements
        await service.ajouter(
          nom: _nomCtrl.text.trim(),
          dosage: _dosageCtrl.text.trim(),
          foisParJour: _fois,
          debut: _debut,
          fin: _fin,
        );
      } else {
        // Médecin : POST /api/medecin/patients/:patientId/traitements
        await service.prescrire(
          patientId: patientId,
          nom: _nomCtrl.text.trim(),
          dosage: _dosageCtrl.text.trim(),
          foisParJour: _fois,
          debut: _debut,
          fin: _fin,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _enregistrement = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _espace(Widget champ) {
    return Padding(padding: const EdgeInsets.only(bottom: 22), child: champ);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: formAppBar(AppStrings.nouveauMedicamentTitre),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              _espace(
                TextFormField(
                  controller: _nomCtrl,
                  validator: _obligatoire,
                  textInputAction: TextInputAction.next,
                  style: formTextStyle,
                  decoration: formDecoration(
                    AppStrings.nomMedicament,
                    Icons.medication_outlined,
                  ),
                ),
              ),
              _espace(
                TextFormField(
                  controller: _dosageCtrl,
                  validator: _obligatoire,
                  textInputAction: TextInputAction.next,
                  style: formTextStyle,
                  decoration: formDecoration(
                    AppStrings.dosage,
                    Icons.science_outlined,
                  ),
                ),
              ),
              _espace(
                DropdownButtonFormField<int>(
                  initialValue: _fois,
                  isExpanded: true,
                  style: formTextStyle,
                  decoration: formDecoration(
                    AppStrings.foisParJourLabel,
                    Icons.repeat,
                  ),
                  items: List.generate(
                    6,
                    (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                  onChanged: (v) => _fois = v ?? 1,
                ),
              ),
              _espace(
                TextFormField(
                  controller: _debutCtrl,
                  readOnly: true,
                  onTap: _choisirDebut,
                  style: formTextStyle,
                  decoration: formDecoration(
                    AppStrings.dateDebut,
                    Icons.calendar_today_outlined,
                  ),
                ),
              ),
              _espace(
                TextFormField(
                  controller: _finCtrl,
                  readOnly: true,
                  onTap: _choisirFin,
                  validator: _validerFin,
                  style: formTextStyle,
                  decoration: formDecoration(
                    AppStrings.dateFin,
                    Icons.event_available_outlined,
                  ).copyWith(
                    // Cross to remove the end date.
                    suffixIcon: _fin == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textGrey),
                            onPressed: () => setState(() {
                              _fin = null;
                              _finCtrl.clear();
                            }),
                          ),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}