import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart';

class OnboardingData {
  final String image;
  final String title;
  final String description;

  const OnboardingData(this.image, this.title, this.description);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<OnboardingData> pages = const [
    OnboardingData(
      'assets/images/onboarding_1_calendar.png',
      'Ne manquez plus vos rendez-vous, vos médicaments et vos analyses de laboratoire...',
      'Suivez tous vos rendez-vous, vos médicaments et vos analyses de laboratoire en un seul endroit.',
    ),
    OnboardingData(
      'assets/images/onboarding_2_map.png',
      'Voir les médecins spécialisés, les cliniques, les pharmacies et les laboratoires près de chez vous',
      'Trouvez facilement les meilleurs spécialistes et établissements de santé à proximité.',
    ),
    OnboardingData(
      'assets/images/onboarding_3_community.png',
      'Une communauté prête à vous aider',
      'Connectez-vous avec d’autres patients et bénéficiez de leur soutien.',
    ),
    OnboardingData(
      'assets/images/onboarding_4_running.png',
      'Nutrition et activité physique pour une meilleure santé des patients atteints de lupus',
      'Découvrez des conseils personnalisés pour améliorer votre bien-être physique et mental.',
    ),
    OnboardingData(
      'assets/images/onboarding_5_records.png',
      'Enregistrez vos dossiers médicaux en toute sécurité avec votre médecin et votre pharmacien',
      'Gardez toutes vos informations médicales au même endroit, accessibles facilement et en toute sécurité.',
    ),
    OnboardingData(
      'assets/images/onboarding_6_messages.png',
      'Messages privés dans l’application avec vos médecins, membres de la communauté...',
      'Communiquez facilement et en toute confidentialité avec vos médecins et d’autres patients.',
    ),
    OnboardingData(
      'assets/images/onboarding_7_video.png',
      'Consultations vidéo avec Dr. Saliha',
      'Accédez à des consultations en ligne avec des spécialistes, où que vous soyez.',
    ),
  ];

  void _next() {
    if (_index < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 42,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _index == 0
                        ? null
                        : () => _controller.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            ),
                    icon: const Icon(Icons.chevron_left, color: AppTheme.purple),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _next,
                    child: Row(
                      children: const [
                        Text('Suivant', style: TextStyle(color: AppTheme.purple, fontSize: 12)),
                        Icon(Icons.chevron_right, size: 16, color: AppTheme.purple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, i) {
                  final page = pages[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        SizedBox(
                          height: 175,
                          width: double.infinity,
                          child: Image.asset(page.image, fit: BoxFit.contain),
                        ),
                        const Spacer(flex: 1),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.purple,
                            fontSize: 17,
                            height: 1.18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const Spacer(flex: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            pages.length,
                            (dot) => AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _index == dot ? 7 : 5,
                              height: _index == dot ? 7 : 5,
                              decoration: BoxDecoration(
                                color: _index == dot
                                    ? AppTheme.purple
                                    : const Color(0xFFDCC8E3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.purple,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: Text(_index == pages.length - 1 ? 'Commencer' : 'Suivant'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
