import '../../domain/entities/bank_transaction.dart';
import 'base_bank_parser.dart';

class PeoplesBankParser extends BaseBankParser {
  @override
  String get bankName => 'Peoples Bank';

  @override
  List<String> get supportedSenderIds => ['PEOPLES BANK', 'PEOPLES_BK'];

  // ─── Compiled regex patterns ──────────────────────────────────────────────

  static final _amountRe = RegExp(r'Rs\.\s*([\d,]+\.\d{2})');
  static final _accountRe = RegExp(r'A/C\s*\(?([\d*\-]+)\)?');
  static final _merchantRe = RegExp(r'\((?:ATM|POS)[^)]*?at\s+([^)]+)\)');
  static final _dateTimeRe = RegExp(r'(?:@|at\s)(\d{2}:\d{2})\s+(\d{2}/\d{2}/\d{4})');

  // ────────────────────────────────────────────────────────────────────────

  @override
  // [වෙනස] smsDate පරාමිතිය එක් කර ඇත
  BankTransaction? parse(String body, {DateTime? smsDate}) {
    final cleanBody = cleanText(body);

    if (cleanBody.contains('OTP') ||
        cleanBody.contains('declined') ||
        cleanBody.contains('Insufficient')) {
      return null;
    }

    final amountMatch = _amountRe.firstMatch(cleanBody);
    if (amountMatch == null) return null;

    final accountMatch = _accountRe.firstMatch(cleanBody);
    if (accountMatch == null) return null;

    // [වෙනස] ආරක්ෂාව සඳහා tryParse භාවිතය
    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    if (amount == null) return null;

    final accountNo = accountMatch
        .group(1)!
        .replaceAll('-', '')
        .replaceAll('*', '');

    final isIncome = cleanBody.toLowerCase().contains('credited');

    final isAtm = cleanBody.contains('(ATM @') ||
        cleanBody.contains('Cash Withd');

    final merchantMatch = _merchantRe.firstMatch(cleanBody);
    String? merchant = merchantMatch?.group(1)?.trim();

    if (merchant == null && cleanBody.contains('Loan Rec.')) {
      merchant = 'Loan Repayment';
    }

    // [වෙනස] අතීත SMS දත්ත වල දිනය ලබාගැනීම සඳහා smsDate යැවීම
    final date = _parseDate(cleanBody, smsDate);

    return BankTransaction(
      bankName: bankName,
      amount: amount,
      isIncome: isIncome,
      accountNo: accountNo,
      merchant: merchant,
      isAtmWithdrawal: isAtm,
      rawBody: body,
      date: date,
    );
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  // [වෙනස] smsDate fallback එකක් ලෙස එකතු කර ඇත
  DateTime _parseDate(String cleanBody, DateTime? smsDate) {
    final m = _dateTimeRe.firstMatch(cleanBody);
    if (m == null) return smsDate ?? DateTime.now();
    try {
      final time = m.group(1)!.split(':');
      final date = m.group(2)!.split('/');
      return DateTime(
        int.parse(date[2]),
        int.parse(date[1]),
        int.parse(date[0]),
        int.parse(time[0]),
        int.parse(time[1]),
      );
    } catch (_) {
      return smsDate ?? DateTime.now();
    }
  }
}