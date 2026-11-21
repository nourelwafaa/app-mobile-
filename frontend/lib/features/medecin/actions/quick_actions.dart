import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/features/medecin/actions/actions_sheet.dart';
import 'package:lupus_plus/features/medecin/agenda/new_rdv_page.dart';
import 'package:lupus_plus/features/medecin/messages/chat_page.dart';
import 'package:lupus_plus/features/medecin/patients/add_document_page.dart';
import 'package:lupus_plus/features/medecin/patients/add_patient_page.dart';
import 'package:lupus_plus/features/medecin/patients/add_traitement_page.dart';
import 'package:lupus_plus/features/medecin/patients/choose_patient_page.dart';
import 'package:lupus_plus/models/document_medical.dart';
import 'package:lupus_plus/models/patient.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// Called by the center "+" button: shows the sheet, then runs the chosen action.
Future<void> ouvrirActionsRapides(BuildContext context) async {
  // Taken before the first "await" so they stay valid afterwards.
  final nav = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);

  final action = await showActionsRapides(context);
  if (action == null) return;

  switch (action) {
    case ActionRapide.ajouterPatient:
      await _ajouterPatient(nav, messenger);
    case ActionRapide.nouveauRdv:
      await _nouveauRdv(nav, messenger);
    case ActionRapide.prescrireTraitement:
      await _prescrire(nav, messenger);
    case ActionRapide.ajouterCompteRendu:
      await _compteRendu(nav, messenger);
    case ActionRapide.envoyerMessage:
      await _envoyerMessage(nav);
  }
}

// Short message at the bottom of the screen.
void _afficher(ScaffoldMessengerState messenger, String texte) {
  messenger.showSnackBar(SnackBar(content: Text(texte)));
}

// Opens the "choose a patient" page and returns the patient (null if back).
Future<Patient?> _choisirPatient(NavigatorState nav) {
  return nav.push<Patient>(
    MaterialPageRoute(builder: (_) => const ChoosePatientPage()),
  );
}

Future<void> _ajouterPatient(
  NavigatorState nav,
  ScaffoldMessengerState messenger,
) async {
  final ajoute = await nav.push<bool>(
    MaterialPageRoute(builder: (_) => const AddPatientPage()),
  );
  if (ajoute == true) _afficher(messenger, AppStrings.patientAjoute);
}

Future<void> _nouveauRdv(
  NavigatorState nav,
  ScaffoldMessengerState messenger,
) async {
  final patients = await MedecinService().getPatients();
  final date = await nav.push<DateTime>(
    MaterialPageRoute(
      builder: (_) => NewRdvPage(patients: patients, dateInitiale: DateTime.now()),
    ),
  );
  if (date != null) _afficher(messenger, AppStrings.rdvAjoute);
}

Future<void> _prescrire(
  NavigatorState nav,
  ScaffoldMessengerState messenger,
) async {
  final patient = await _choisirPatient(nav);
  if (patient == null) return;
  final ok = await nav.push<bool>(
    MaterialPageRoute(builder: (_) => AddTraitementPage(patientId: patient.id)),
  );
  if (ok == true) _afficher(messenger, AppStrings.medicamentAjoute);
}

Future<void> _compteRendu(
  NavigatorState nav,
  ScaffoldMessengerState messenger,
) async {
  final patient = await _choisirPatient(nav);
  if (patient == null) return;
  final ok = await nav.push<bool>(
    MaterialPageRoute(
      builder: (_) => AddDocumentPage(
        patientId: patient.id,
        typeInitial: TypeDocument.compteRendu, // preselected
      ),
    ),
  );
  if (ok == true) _afficher(messenger, AppStrings.documentAjoute);
}

Future<void> _envoyerMessage(NavigatorState nav) async {
  final patient = await _choisirPatient(nav);
  if (patient == null) return;
  await nav.push(MaterialPageRoute(builder: (_) => ChatPage(patient: patient)));
}