import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/date_format.dart';
import 'package:lupus_plus/models/message.dart';
import 'package:lupus_plus/providers/auth_provider.dart';
import 'package:lupus_plus/services/messages_service.dart';

/// Discussion du patient avec un médecin qui le suit (séance 7).
/// Même design que la discussion du médecin (features/medecin/messages/chat_page.dart).
/// La discussion ouverte se recharge toutes les 5 secondes.
///
/// [medecinId] null = ouvert depuis « Trouver un pro » (fausse liste, séance 8) :
/// on ne peut pas écrire, seulement à un médecin qui suit le patient.
class ChatScreen extends StatefulWidget {
  final int? medecinId;
  final String doctorName; // "Dr Karim Martin"
  final String speciality;

  const ChatScreen({
    super.key,
    this.medecinId,
    required this.doctorName,
    required this.speciality,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Duration _intervalle = Duration(seconds: 5);

  late final MessagesService _service;
  final TextEditingController _champ = TextEditingController();
  Timer? _timer;

  List<Message> _messages = [];
  bool _chargement = true;
  bool _envoi = false;

  bool get _peutEcrire => widget.medecinId != null;

  // Lettre du cercle : nom de famille ("M" pour Dr Martin).
  String get _initiale {
    final mots = widget.doctorName.trim().split(RegExp(r'\s+'));
    final dernier = mots.isEmpty ? '' : mots.last;
    return dernier.isEmpty ? '?' : dernier[0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _service = MessagesService(context.read<AuthProvider>().api);
    _champ.addListener(_surChangementTexte);
    if (_peutEcrire) {
      _charger();
      _timer = Timer.periodic(_intervalle, (_) => _charger());
    } else {
      _chargement = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _champ.removeListener(_surChangementTexte);
    _champ.dispose();
    super.dispose();
  }

  // Active le bouton d'envoi seulement quand il y a du texte.
  void _surChangementTexte() {
    if (mounted) setState(() {});
  }

  /// GET /api/patients/me/messages/:medecinId (les messages reçus passent en « lu »)
  Future<void> _charger() async {
    try {
      final liste = await _service.getMessagesMedecin(widget.medecinId!);
      if (!mounted) return;
      setState(() {
        _messages = liste;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  /// POST /api/patients/me/messages/:medecinId
  Future<void> _envoyer() async {
    final texte = _champ.text.trim();
    if (texte.isEmpty || _envoi || !_peutEcrire) return;

    setState(() => _envoi = true);
    try {
      await _service.ecrireAuMedecin(widget.medecinId!, texte);
      _champ.clear();
      await _charger();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() => _envoi = false);
  }

  // Messages + un séparateur (DateTime) avant chaque nouveau jour.
  List<Object> _lignes() {
    final items = <Object>[];
    DateTime? dernierJour;
    for (final m in _messages) {
      final jour = DateTime(m.date.year, m.date.month, m.date.day);
      if (dernierJour == null || jour != dernierJour) {
        items.add(jour);
        dernierJour = jour;
      }
      items.add(m);
    }
    return items;
  }

  // ---------- Widgets ----------

  // Barre du haut : flèche, avatar, nom du médecin, spécialité.
  Widget _entete() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.chevron_left,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.iconSquare,
            child: Text(
              _initiale,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (widget.speciality.isNotEmpty)
                  Text(
                    widget.speciality,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // « Aujourd'hui », « Hier » ou « lundi 16 novembre ».
  Widget _separateur(DateTime jour) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          formatJourMessage(jour),
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ),
    );
  }

  // Une bulle + son heure. Médecin : blanc, à gauche. Patient (moi) : violet, à droite.
  Widget _bulle(Message m) {
    final moi = m.deMoi;
    final largeurMax = MediaQuery.of(context).size.width * 0.72;

    final bulle = Container(
      constraints: BoxConstraints(maxWidth: largeurMax),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: moi ? AppColors.primary : AppColors.card,
        border: moi ? null : Border.all(color: AppColors.iconSquare),
        // Le coin du côté de l'expéditeur est moins arrondi.
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(moi ? 16 : 4),
          bottomRight: Radius.circular(moi ? 4 : 16),
        ),
      ),
      child: Text(
        m.texte,
        style: TextStyle(
          fontSize: 14,
          height: 1.35,
          color: moi ? Colors.white : AppColors.textDark,
        ),
      ),
    );

    final heure = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        formatHeure(m.date),
        style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
      ),
    );

    if (moi) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [bulle, heure],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.iconSquare,
            child: Text(
              _initiale,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [bulle, heure],
          ),
        ],
      ),
    );
  }

  // Zone des messages.
  Widget _corps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_peutEcrire) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            AppStrings.ecrireSeulementMedecinSuivi,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          AppStrings.aucunMessage,
          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
      );
    }

    final items = _lignes();
    // reverse : la liste commence en bas (dernier message visible).
    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[items.length - 1 - index];
          if (item is DateTime) return _separateur(item);
          return _bulle(item as Message);
        },
      ),
    );
  }

  OutlineInputBorder get _sansBordure => OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      );

  // Barre du bas : champ de texte + bouton rond d'envoi.
  Widget _barreSaisie() {
    final peutEnvoyer =
        _peutEcrire && _champ.text.trim().isNotEmpty && !_envoi;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.iconSquare)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _champ,
              enabled: _peutEcrire,
              minLines: 1,
              maxLines: 4, // grandit jusqu'à 4 lignes
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: AppStrings.ecrivezMessage,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
                filled: true,
                fillColor: AppColors.iconSquare,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: _sansBordure,
                enabledBorder: _sansBordure,
                disabledBorder: _sansBordure,
                focusedBorder: _sansBordure,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: peutEnvoyer ? AppColors.primary : AppColors.sendDisabled,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: peutEnvoyer ? _envoyer : null,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.send, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _entete(),
            const Divider(height: 1, color: AppColors.iconSquare),
            Expanded(child: _corps()),
            _barreSaisie(),
          ],
        ),
      ),
    );
  }
}
