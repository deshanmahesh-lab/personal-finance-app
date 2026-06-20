import '../../domain/entities/bank_transaction.dart';
import 'base_bank_parser.dart';

/// Parser for Bank of Ceylon (BOC) SMS transaction alerts.
///
/// Verified against 31 real-world SMS samples covering:
///   POS/ATM Transaction · ATM Withdrawal · Transfer Debit
///   Transfer Order Debit · No Book Deposit S/A
class BocParser extends BaseBankParser {
  @override
  String get bankName => 'BOC';

  @override
  List<String> get supportedSenderIds => ['BOC', 'BOC_SMS', 'BOC_ALERT'];

  // ---------------------------------------------------------------------------
  // Static regex constants — compiled exactly once, reused for every parse()
  // ---------------------------------------------------------------------------

  /// Matches the PRIMARY (first) Rs amount — the transaction amount.
  /// The closing balance always appears after "Balance available", so
  /// firstMatch() is guaranteed to pick the transaction amount.
  ///
  /// Handles: Rs 50.00 · Rs 5030.00 · Rs 46579.93 · Rs 105,513.73
  /// Does NOT match: Rs .00 (zero-balance edge case in 2 SMS — intentional;
  /// firstMatch() already captured the tx amount before reaching the balance).
  static final _amountRegex = RegExp(r'Rs\s+([\d,]+\.\d{2})');

  /// Matches the closing balance INCLUDING the "Rs .00" (no leading digit)
  /// edge case seen in 2 zero-balance SMS. Use this if you add balance
  /// extraction to BankTransaction later.
  ///
  ///   "Balance available Rs 3963.16"  → group(1) = "3963.16"
  ///   "Balance available Rs .00"      → group(1) = ".00"  → double 0.0
  static final _balanceRegex = RegExp(r'Balance available Rs\s*([\d]*\.[\d]{2})');

  /// Matches masked account numbers: XXXXXXXXXX378
  static final _accountRegex = RegExp(r'A/C\s+No\s+([X\d]+)');

  // ---------------------------------------------------------------------------
  // parse
  // ---------------------------------------------------------------------------

  /// Parses a single BOC SMS body into a [BankTransaction].
  ///
  /// [body]    — Raw SMS text (not yet cleaned).
  /// [smsDate] — **Strongly recommended.** Pass the timestamp from the SMS
  ///             metadata here. Falls back to DateTime.now() when null, which
  ///             loses the real transaction date.
  ///
  /// ⚠ ARCHITECTURE NOTE: to fully fix Bug #1, update BaseBankParser's
  ///   abstract signature to:
  ///     BankTransaction? parse(String body, {DateTime? smsDate});
  ///   All concrete parsers then receive the date from the SMS reader.
  @override
  BankTransaction? parse(String body, {DateTime? smsDate}) {
    // cleanText() is inherited from BaseBankParser.
    // We toLowerCase() defensively so contains() checks survive any
    // normalization that cleanText() may apply (Bug #3 fix).
    final rawClean  = cleanText(body);
    final lowerBody = rawClean.toLowerCase();

    // ── Gate: only transactional SMS carry "balance available" ──────────────
    if (!lowerBody.contains('balance available')) return null;

    // ── Transaction amount ───────────────────────────────────────────────────
    // Use rawClean (not lowerBody) so the regex matches the original casing
    // of "Rs" exactly as BOC sends it.
    final amountMatch = _amountRegex.firstMatch(rawClean);
    if (amountMatch == null) return null;

    // Bug #2 fix: tryParse instead of parse — returns null on malformed input.
    final amount = double.tryParse(
      amountMatch.group(1)!.replaceAll(',', ''),
    );
    if (amount == null) return null;

    // ── Account number ───────────────────────────────────────────────────────
    final accountMatch = _accountRegex.firstMatch(rawClean);
    if (accountMatch == null) return null;
    final accountNo = accountMatch.group(1)!;

    // ── Transaction direction ────────────────────────────────────────────────
    // Credits carry "To A/C No …" (No Book Deposit S/A pattern).
    // All debits carry "From A/C No …" — "From" does NOT contain "to a/c".
    final isIncome =
        lowerBody.contains('to a/c') || lowerBody.contains('deposit');

    // ── ATM cash-withdrawal flag ─────────────────────────────────────────────
    // "POS/ATM Transaction" is a card payment — NOT flagged as an ATM
    // withdrawal even though it contains "ATM" in the prefix.
    final isAtm = lowerBody.contains('atm withdrawal');

    return BankTransaction(
      bankName       : bankName,
      amount         : amount,
      isIncome       : isIncome,
      accountNo      : accountNo,
      isAtmWithdrawal: isAtm,
      rawBody        : body,
      // Bug #1: pass smsDate from your SMS reader layer; DateTime.now()
      // is only a safe fallback — it does NOT reflect the real tx date.
      date           : smsDate ?? DateTime.now(),
    );
  }
}