import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/features/medecin/home/widgets/home_header.dart';
import 'package:lupus_plus/features/medecin/home/widgets/patient_tile.dart';
import 'package:lupus_plus/features/medecin/home/widgets/stat_card.dart';
import 'package:lupus_plus/models/home_data.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// The doctor's home page.
// It is a StatefulWidget because it loads data once when it opens.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MedecinService _service = MedecinService();

  // The data being loaded (will be available "in the future").
  late Future<HomeData> _futureData;

  @override
  void initState() {
    super.initState();
    // Start loading ONCE, when the page opens.
    // (Doing it inside build() would reload the data at every redraw.)
    _futureData = _service.getHomeData();
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
              if (snapshot.connectionState != ConnectionState.done) {
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
        HomeHeader(nomMedecin: data.nomMedecin),
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
            ),
            StatCard(
              icon: Icons.error,
              iconColor: AppColors.iconAlertes,
              backgroundColor: AppColors.cardAlertes,
              value: '${data.alertesAujourdhui}',
              label: AppStrings.alertesAujourdhui,
            ),
            StatCard(
              icon: Icons.calendar_month,
              iconColor: AppColors.iconRdv,
              backgroundColor: AppColors.cardRdv,
              value: '${data.rendezVousAVenir}',
              label: AppStrings.rendezVousAVenir,
            ),
            StatCard(
              icon: Icons.trending_up,
              iconColor: AppColors.iconAmelioration,
              backgroundColor: AppColors.cardAmelioration,
              value: '+${data.ameliorationMoyenne}%',
              label: AppStrings.ameliorationMoyenne,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section title: "Mes patients récents" ........ "Voir tout"
        const Row(
          children: [
            Icon(Icons.people_alt_outlined, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              AppStrings.mesPatientsRecents,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Spacer(),
            // Plain text for now: nothing happens until the patients page exists.
            Text(
              AppStrings.voirTout,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // One row per recent patient.
        // "..." inserts every row of the list into the children above.
        ...data.patientsRecents.map((p) => PatientTile(patient: p)),
      ],
    );
  }
}