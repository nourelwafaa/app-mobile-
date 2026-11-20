// One message of a conversation.
class Message {
  final int id;
  final bool deMoi; // true = sent by the doctor, false = sent by the patient
  final String texte;
  final DateTime date;
  bool lu; // false = patient message not read yet by the doctor

  Message({
    required this.id,
    required this.deMoi,
    required this.texte,
    required this.date,
    required this.lu,
  });
}