import '../../domain/entities/bank_transaction.dart';

abstract class BaseBankParser {
  String get bankName;
  List<String> get supportedSenderIds;

  bool canParse(String sender) {
    final cleanSender = sender.trim().toUpperCase();
    return supportedSenderIds.contains(cleanSender);
  }

  // [වෙනස] සැබෑ SMS දිනය ලබා ගැනීම සඳහා smsDate පරාමිතිය එක් කර ඇත
  BankTransaction? parse(String body, {DateTime? smsDate});

  String cleanText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}