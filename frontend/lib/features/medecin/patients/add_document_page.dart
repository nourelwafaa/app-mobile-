import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/theme/form_style.dart';
import 'package:lupus_plus/models/document_medical.dart';
import 'package:lupus_plus/providers/auth_provider.dart';
import 'package:lupus_plus/services/dossier_service.dart';
import 'package:provider/provider.dart';

// Form to add a document to a patient (no real file yet → backend, séance 5).
// Closes with true when saved.
class AddDocumentPage extends StatefulWidget {
  final int patientId;
  final TypeDocument typeInitial; // type preselected in the form

  const AddDocumentPage({
    super.key,
    required this.patientId,
    this.typeInitial = TypeDocument.ordonnance,
  });

  @override
  State<AddDocumentPage> createState() => _AddDocumentPageState();
}

class _AddDocumentPageState extends State<AddDocumentPage> {
  final _formKey = GlobalKey<FormState>();

  final _titreCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  late TypeDocument _type;
  late DateTime _date;

  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _type = widget.typeInitial;
    final n = DateTime.now();
    _date = DateTime(n.year, n.month, n.day);
    _dateCtrl.text = _format(_date);
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  String _format(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<void> _choisirDate() async {
    final choix = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (choix == null) return;
    setState(() {
      _date = choix;
      _dateCtrl.text = _format(choix);
    });
  }

  String? _obligatoire(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.champObligatoire;
    return null;
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enregistrement = true);

    try {
      // POST /api/medecin/patients/:patientId/documents
      await DossierService(context.read<AuthProvider>().api).ajouterDocument(
        patientId: widget.patientId,
        titre: _titreCtrl.text.trim(),
        type: _type,
        date: _date,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _enregistrement = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
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
      appBar: formAppBar(AppStrings.nouveauDocumentTitre),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              _espace(
                TextFormField(
                  controller: _titreCtrl,
                  validator: _obligatoire,
                  textInputAction: TextInputAction.next,
                  style: formTextStyle,
                  decoration: formDecoration(
                    AppStrings.titreDocument,
                    Icons.description_outlined,
                  ),
                ),
              ),
              _espace(
                DropdownButtonFormField<TypeDocument>(
                  initialValue: _type,
                  isExpanded: true,
                  style: formTextStyle,
                  decoration: formDecoration(
                    AppStrings.typeDocument,
                    Icons.folder_outlined,
                  ),
                  items: TypeDocument.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => _type = v ?? TypeDocument.ordonnance,
                ),
              ),
              _espace(
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _choisirDate,
                  style: formTextStyle,
                  decoration: formDecoration(
                    AppStrings.date,
                    Icons.calendar_today_outlined,
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