import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/features/medecin/home/widgets/home_header.dart';
import 'package:lupus_plus/features/medecin/home/widgets/patient_tile.dart';
import 'package:lupus_plus/features/medecin/home/widgets/stat_card.dart';
import 'package:lupus_plus/models/home_data.dart';
import 'package:lupus_plus/services/espace_medecin_service.dart';
import 'package:lupus_plus/services/medecin_service.dart';
import 'package:provider/provider.dart';
import 'package:lupus_plus/providers/auth_provider.dart';
import 'package:lupus_plus/features/medecin/messages/messages_page.dart';
import 'package:lupus_plus/features/medecin/alerts/alertes_page.dart';
import 'package:lupus_plus/features/medecin/messages/chat_page.dart';
import 'package:lupus_plus/features/medecin/notifications/notifications_page.dart';
import 'package:lupus_plus/models/patient.dart';

// The doctor's home page.
// It is a StatefulWidget because it loads data once when it opens.
class HomePage extends StatefulWidget {
  // Called when the doctor taps "Voir tout" (switches to the Patients tab).
  final VoidCallback? onVoirTout;

  // Called to open the Agenda tab on a given day.
  final ValueChanged<DateTime>? onOuvrirAgenda;

  const HomePage({super.key, this.onVoirTout, this.onOuvrirAgenda});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final EspaceMedecinService _service; // backend (séance 6)

  // The data being loaded (will be available "in the future").
  late Future<HomeData> _futureData;

  @override
  void initState() {
    super.initState();
    _service = EspaceMedecinService(context.read<AuthProvider>().api);
    // GET /api/medecin/accueil
    _futureData = _service.getAccueil();
    // Reload the counters when a patient or an appointment is added.
    MedecinService.patientsChanged.addListener(_recharger);
    MedecinService.rdvChanged.addListener(_recharger);
    MedecinService.alertesChanged.addListener(_recharger);
    MedecinService.messagesChanged.addListener(_recharger); // point rouge Messages
    MedecinService.notificationsChanged.addListener(_recharger); // point rouge cloche
  }
  @override
  void dispose() {
    MedecinService.patientsChanged.removeListener(_recharger);
    MedecinService.rdvChanged.removeListener(_recharger);
    MedecinService.alertesChanged.removeListener(_recharger);
    MedecinService.messagesChanged.removeListener(_recharger);
    MedecinService.notificationsChanged.removeListener(_recharger);
    super.dispose();
  }

  // Loads the data again (the old data stays visible meanwhile).
  void _recharger() {
    if (!mounted) return;
    setState(() {
      _futureData = _service.getAccueil();
    });
  }
  // Opens the conversations list inside the Accueil tab (the bar stays).
  void _ouvrirMessages() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MessagesPage()),
    );
  }

  // Opens the alerts page inside the Accueil tab (the bar stays visible).
  void _ouvrirAlertes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlertesPage()),
    );
  }

  // Opens the notifications inside the Accueil tab (the bar stays visible).
  void _ouvrirNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          onOuvrirAgenda: (jour) => widget.onOuvrirAgenda?.call(jour),
        ),
      ),
    );
  }

  // Opens the Agenda on the day of the next planned appointment (or today).
  Future<void> _ouvrirAgenda() async {
    // Jour du prochain RDV, déjà chargé avec l'accueil.
    DateTime? jour;
    try {
      jour = (await _futureData).prochainRdv;
    } catch (_) {
      jour = null;
    }
    if (!mounted) return;
    widget.onOuvrirAgenda?.call(jour ?? DateTime.now());
  }

  // Opens the chat with a patient (full screen, no bottom bar).
  void _ouvrirChat(Patient patient) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ChatPage(patient: patient)),
    );
  }
  @override
  Widget build(BuildContext context) {
    // SafeArea keeps the content away from the phone's status bar.
    return SafeArea(
      // Stack puts widgets on top of each other: butterfly behind, content in front.
      child: Stack(
        children: [
          // Big faded butterfly in the top-right corner (decoration only).
          Positioned(
            top: 60,
            right: -30, // partly outside the screen, like in the design
            // IgnorePointer: taps go through the butterfly to the content.
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18, // very light
                child: Image.asset('assets/images/lupus_logo.png', width: 190),
              ),
            ),
          ),

          // The real content (same loading logic as before).
          FutureBuilder<HomeData>(
            future: _futureData,
            builder: (context, snapshot) {
              // 1. Still loading: show a spinner.
              if (!snapshot.hasData &&
                  snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Loading failed: show an error message.
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(child: Text(AppStrings.erreurChargement));
              }

              // 3. Data is ready: show the page.
              return _buildContent(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  // The page content, once the data is loaded.
  Widget _buildContent(HomeData data) {
    // ListView = scrollable column (useful on small screens).
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Logo, names, avatar and greeting.
        HomeHeader(
          nomMedecin: data.nomMedecin,
          messagesNonLus: data.messagesNonLus > 0,
          notificationsNonLues: data.notificationsNonLues > 0,
          onMessages: _ouvrirMessages,
          onNotifications: _ouvrirNotifications,
        ),
        const SizedBox(height: 24),

        // The 4 counter cards in 2 columns.
        // shrinkWrap + NeverScrollable: the grid takes only the space it needs
        // and the ListView handles the scrolling.
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // Width / height of a card. Lower it (e.g. 1.3) if the text overflows.
          childAspectRatio: 1.45,
          children: [
            StatCard(
              icon: Icons.groups,
              iconColor: AppColors.iconPatients,
              backgroundColor: AppColors.cardPatients,
              value: '${data.patientsSuivis}',
              label: AppStrings.patientsSuivis,
              onTap: widget.onVoirTout,
            ),
            StatCard(
              icon: Icons.error,
              iconColor: AppColors.iconAlertes,
              backgroundColor: AppColors.cardAlertes,
              value: '${data.alertesAujourdhui}',
              label: AppStrings.alertesAujourdhui,
              onTap: _ouvrirAlertes,
            ),
            StatCard(
              icon: Icons.calendar_month,
              iconColor: AppColors.iconRdv,
              backgroundColor: AppColors.cardRdv,
              value: '${data.rendezVousAVenir}',
              label: AppStrings.rendezVousAVenir,
              onTap: _ouvrirAgenda,
            ),
            StatCard(
              icon: Icons.trending_up,
              iconColor: AppColors.iconAmelioration,
              backgroundColor: AppColors.cardAmelioration,
              // "+12%" si la douleur baisse, "-5%" si elle augmente
              value: data.ameliorationMoyenne >= 0
                  ? '+${data.ameliorationMoyenne}%'
                  : '${data.ameliorationMoyenne}%',
              label: AppStrings.ameliorationMoyenne,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section title: "Mes patients récents" ........ "Voir tout"
        Row(
          children: [
            const Icon(
              Icons.people_alt_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              AppStrings.mesPatientsRecents,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            // Tap: opens the Patients tab.
            GestureDetector(
              onTap: widget.onVoirTout,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Text(
                  AppStrings.voirTout,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // One row per recent patient.
        // "..." inserts every row of the list into the children above.
        ...data.patientsRecents.map(
          (p) => PatientTile(patient: p, onTap: () => _ouvrirChat(p)),
        ),
      ],
    );
  }
}