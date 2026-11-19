import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';
import '../models/models.dart';

/// true  = mode démo : aucun serveur nécessaire, tout est simulé
/// false = vraie connexion au backend Node.js
const bool kDemoMode = false;

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient api = ApiClient();
  final _storage = const FlutterSecureStorage();

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  PatientProfile? profile;

  // Données locales utilisées uniquement en mode démo
  String? _demoSexe = 'femme';
  double? _demoPoids;
  double? _demoTaille;
  String? _demoGroupe;

  int? _calcAge(String? date) {
    if (date == null) return null;
    final d = DateTime.tryParse(date);
    if (d == null) return null;
    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return age;
  }

  AuthProvider() {
    api.onUnauthorized = () => logout();
  }

  /// À appeler au démarrage : restaure la session si un token est sauvegardé
  Future<void> init() async {
    if (kDemoMode) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final token = await _storage.read(key: 'token');
      final userJson = await _storage.read(key: 'user');
      if (token != null && userJson != null) {
        api.token = token;
        user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        status = AuthStatus.authenticated;
      } else {
        status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _startSession(
    Map<String, dynamic> data, {
    bool remember = true,
  }) async {
    api.token = data['token'] as String;
    user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    profile = null;
    try {
      if (remember) {
        await _storage.write(key: 'token', value: api.token);
        await _storage.write(key: 'user', value: jsonEncode(user!.toJson()));
      } else {
        await _storage.deleteAll();
      }
    } catch (_) {}
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// POST /api/auth/login
  Future<void> login({
    required String identifiant,
    required String motDePasse,
    bool remember = true,
  }) async {
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      user = AppUser(
        id: 1,
        nomComplet: 'Sarah Benali',
        email: identifiant.contains('@') ? identifiant : 'sarah@mail.com',
        telephone: '0555123456',
        dateNaissance: '2000-05-15',
        // astuce démo : un email qui contient "medecin" ouvre l'espace médecin
        role: identifiant.toLowerCase().contains('medecin')
            ? 'medecin'
            : 'patient',
      );
      status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }
    final data = await api.post('/auth/login', {
      'identifiant': identifiant.trim(),
      'mot_de_passe': motDePasse,
    });
    await _startSession(data, remember: remember);
  }

  /// POST /api/auth/register
  Future<void> register(RegisterDraft d, {required String role}) async {
    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      user = AppUser(
        id: 1,
        nomComplet: d.nomComplet.trim(),
        email: d.email.trim(),
        telephone: d.telephone,
        dateNaissance: d.dateNaissance,
        role: role,
      );
      status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }
    final data = await api.post('/auth/register', {
      'nom_complet': d.nomComplet.trim(),
      'email': d.email.trim(),
      if (d.telephone != null && d.telephone!.trim().isNotEmpty)
        'telephone': d.telephone!.trim(),
      'mot_de_passe': d.motDePasse,
      if (d.dateNaissance != null) 'date_naissance': d.dateNaissance,
      'role': role,
    });
    await _startSession(data);
  }

  /// GET /api/patients/me
  Future<void> loadProfile() async {
    if (kDemoMode) {
      profile = PatientProfile(
        user: user!,
        age: _calcAge(user!.dateNaissance),
        sexe: _demoSexe,
        poids: _demoPoids,
        taille: _demoTaille,
        groupeSanguin: _demoGroupe,
      );
      notifyListeners();
      return;
    }
    final data = await api.get('/patients/me');
    profile = PatientProfile.fromJson(data);
    notifyListeners();
  }

  /// PUT /api/patients/me/infos  (seuls les champs non nuls sont envoyés)
  Future<void> saveInfos({
    String? sexe,
    double? poids,
    double? taille,
    String? groupeSanguin,
  }) async {
    if (kDemoMode) {
      _demoSexe = sexe ?? _demoSexe;
      _demoPoids = poids ?? _demoPoids;
      _demoTaille = taille ?? _demoTaille;
      _demoGroupe = groupeSanguin ?? _demoGroupe;
      await loadProfile();
      return;
    }
    await api.put('/patients/me/infos', {
      if (sexe != null) 'sexe': sexe,
      if (poids != null) 'poids': poids,
      if (taille != null) 'taille': taille,
      if (groupeSanguin != null) 'groupe_sanguin': groupeSanguin,
    });
    await loadProfile();
  }

  Future<void> logout() async {
    api.token = null;
    user = null;
    profile = null;
    try {
      await _storage.deleteAll();
    } catch (_) {}
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}