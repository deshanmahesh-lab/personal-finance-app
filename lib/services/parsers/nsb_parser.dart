import '../../domain/entities/bank_transaction.dart';
import 'base_bank_parser.dart';

class NsbParser extends BaseBankParser {
  @override
  String get bankName => 'National Savings Bank';

  @override
  List<String> get supportedSenderIds => ['NSB', 'NSB_ALERT'];

  // ─── Pre-compiled RegExp patterns ───────────────────────────────────────────

  static final _amountRegex = RegExp(
    r'LKR\s*([\d,]+\.\d{2})\s+(?:Debited|Credited)',
  );

  static final _accountRegex = RegExp(r'A/c\s+([X\d]+)');

  static final _dateRegex = RegExp(
    r'on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2})',
  );

  static final _merchantRegex = RegExp(r'@\s*([^.@]+)\.');

  static final _descriptionRegex = RegExp(
    r'(Debit Card Annual Fee'
    r'|ATM (?:POS Transaction|Cash Withdrawal)'
    r'|(?:Transaction\s+)?Domestic Clearing[^.]+)',
  );

  // ─── parse ───────────────────────────────────────────────────────────────────

  @override
  BankTransaction? parse(String body, {DateTime? smsDate}) { // [වෙනස] smsDate එකතු කළා
    final cleanBody = cleanText(body);

    if (!cleanBody.contains('AvlBal')) return null;

    if (RegExp(r'otp|valid for \d+ min', caseSensitive: false).hasMatch(cleanBody)) {
      return null;
    }

    final amountMatch = _amountRegex.firstMatch(cleanBody);
    if (amountMatch == null) return null;

    final amount = double.tryParse( // [වෙනස] parse වෙනුවට tryParse දැම්මා ආරක්ෂාවට
      amountMatch.group(1)!.replaceAll(',', ''),
    );
    if (amount == null) return null;

    final accountMatch = _accountRegex.firstMatch(cleanBody);
    if (accountMatch == null) return null;
    final accountNo = accountMatch.group(1)!;

    // ── Transaction date ─────────────────────────────────────────────────────
    // SMS එක ඇතුළෙන්ම දිනය හොයාගන්නවා. බැරි වුණොත් smsDate හෝ අද දිනය දානවා.
    DateTime transactionDate = smsDate ?? DateTime.now();
    final dateMatch = _dateRegex.firstMatch(cleanBody);

    if (dateMatch != null) {
      try {
        final d = dateMatch.group(1)!.split('/'); // [dd, MM, yyyy]
        final t = dateMatch.group(2)!.split(':'); // [HH, mm]
        transactionDate = DateTime(
          int.parse(d[2]), // year
          int.parse(d[1]), // month
          int.parse(d[0]), // day
          int.parse(t[0]), // hour
          int.parse(t[1]), // minute
        );
      } catch (_) {
        // වැරදුණොත් fallback එකට යනවා
      }
    }

    final isIncome = cleanBody.contains('Credited to');
    final isAtm = cleanBody.contains('ATM Cash Withdrawal');

    final rawMerchant = _merchantRegex.firstMatch(cleanBody)?.group(1)?.trim();

    final merchant = (rawMerchant == null || rawMerchant.isEmpty)
        ? _descriptionRegex.firstMatch(cleanBody)?.group(1)?.trim()
        : rawMerchant;

    return BankTransaction(
      bankName: bankName,
      amount: amount,
      isIncome: isIncome,
      accountNo: accountNo,
      merchant: merchant,
      isAtmWithdrawal: isAtm,
      rawBody: body,
      date: transactionDate,
    );
  }
}