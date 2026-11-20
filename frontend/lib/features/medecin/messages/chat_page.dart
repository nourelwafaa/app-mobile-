import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/core/utils/date_format.dart';
import 'package:lupus_plus/features/medecin/patients/patient_fiche_page.dart';
import 'package:lupus_plus/models/message.dart';
import 'package:lupus_plus/models/patient.dart';
import 'package:lupus_plus/services/medecin_service.dart';

// The chat with one patient.
class ChatPage extends StatefulWidget {
  final Patient patient;
  final bool depuisFiche; // true = opened from the patient file

  const ChatPage({super.key, required this.patient, this.depuisFiche = false});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final MedecinService _service = MedecinService();
  final TextEditingController _champ = TextEditingController();

  List<Message> _messages = [];
  bool _chargement = true;
  bool _envoi = false;

  Patient get _p => widget.patient;

  @override
  void initState() {
    super.initState();
    _champ.addListener(_surChangementTexte);
    _charger();
  }

  @override
  void dispose() {
    _champ.removeListener(_surChangementTexte);
    _champ.dispose();
    super.dispose();
  }

  // Refreshes the send button (enabled only when there is some text).
  void _surChangementTexte() {
    if (mounted) setState(() {});
  }

  Future<void> _charger() async {
    final liste = await _service.getMessages(_p.id);
    if (!mounted) return;
    setState(() {
      _messages = liste;
      _chargement = false;
    });
    // Opening the chat marks the patient's messages as read.
    _service.marquerLu(_p.id);
  }

  Future<void> _envoyer() async {
    final texte = _champ.text.trim();
    if (texte.isEmpty || _envoi) return;

    setState(() => _envoi = true);
    _champ.clear();

    await _service.envoyerMessage(_p.id, texte);
    final liste = await _service.getMessages(_p.id);
    if (!mounted) return;
    setState(() {
      _messages = liste;
      _envoi = false;
    });
  }

  // "Fiche" link: back to the file if we came from it, otherwise open it.
  void _ouvrirFiche() {
    if (widget.depuisFiche) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PatientFichePage(patient: _p)),
    );
  }

  // Messages + one date separator (a DateTime) before each new day.
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

  // Top bar: back arrow, avatar, name, "26 ans · patiente suivie", "Fiche".
  Widget _entete() {
    final role = _p.sexe == 'Femme'
        ? AppStrings.patienteSuivie
        : AppStrings.patientSuivi;
    final sousTitre = [
      if (_p.age != null) '${_p.age} ${AppStrings.ans}',
      role,
    ].join(' · ');

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
              _p.initiale,
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
                  _p.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  sousTitre,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _ouvrirFiche,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                AppStrings.fiche,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // "Aujourd'hui", "Hier" or "lundi 16 novembre".
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

  // One bubble + its time. Patient: white, left. Doctor: purple, right.
  Widget _bulle(Message m) {
    final moi = m.deMoi;
    final largeurMax = MediaQuery.of(context).size.width * 0.72;

    final bulle = Container(
      constraints: BoxConstraints(maxWidth: largeurMax),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: moi ? AppColors.primary : AppColors.card,
        border: moi ? null : Border.all(color: AppColors.iconSquare),
        // The corner next to the sender is less rounded.
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
              _p.initiale,
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

  // Messages area.
  Widget _corps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
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
    // reverse: the list starts at the bottom (newest message visible).
    // Align + shrinkWrap: few messages stay at the top, like in the design.
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

  // Bottom bar: text field + round send button.
  Widget _barreSaisie() {
    final peutEnvoyer = _champ.text.trim().isNotEmpty && !_envoi;

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
              minLines: 1,
              maxLines: 4, // grows up to 4 lines
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