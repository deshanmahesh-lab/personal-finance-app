import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../data/datasources/app_database.dart';
import '../data/datasources/daos/transaction_dao.dart';
import '../data/datasources/daos/account_dao.dart';
import '../data/datasources/daos/category_dao.dart';
import '../data/datasources/daos/category_rule_dao.dart';

class SmsParserService {
  final SmsQuery _query = SmsQuery();
  final AppDatabase _db;
  late final TransactionDao _txDao;
  late final AccountDao _accDao;
  late final CategoryDao _catDao;
  late final CategoryRuleDao _ruleDao;

  SmsParserService(this._db) {
    _txDao = _db.transactionDao;
    _accDao = _db.accountDao;
    _catDao = _db.categoryDao;
    _ruleDao = _db.categoryRuleDao;
  }

  final RegExp _amountRegex = RegExp(r'(?:Rs\.|LKR)\s*([\d,]+\.\d{2}|[\d,]+)', caseSensitive: false);
  final RegExp _debitRegex = RegExp(r'\b(debited|paid|withdrawn|purchase|deducted|spent)\b', caseSensitive: false);
  final RegExp _creditRegex = RegExp(r'\b(credited|deposited|received|refunded|reversal|reversed|cashback|salary)\b', caseSensitive: false);
  final RegExp _atmNoiseRegex = RegExp(r'\b(fee|charge|failed|balance|inquiry)\b', caseSensitive: false);

  final Map<RegExp, String> _tier2Regex = {
    RegExp(r'\b(KEELLS|CARGILLS|SATHOSA|FOODCITY|ARPICO|KFC|PIZZA HUT|MCDONALDS)\b', caseSensitive: false): 'Food & Dining',
    RegExp(r'\b(CEYPETCO|IOC|LAUGFS PETROLEUM|UBER|PICKME)\b', caseSensitive: false): 'Transport',
    RegExp(r'\b(DIALOG|MOBITEL|AIRTEL|HUTCH|SLT|CEB|WATER BOARD|NWSDB)\b', caseSensitive: false): 'Bills & Utilities',
    RegExp(r'\b(HOSPITAL|PHARMACY|ASIRI|NAWALOKA|DURDANS)\b', caseSensitive: false): 'Health & Fitness',
  };

  String _normalizeText(String raw) {
    return raw.toUpperCase()
        .replaceAll(RegExp(r'[0-9]'), '')
        .replaceAll(RegExp(r'[^A-Z\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<void> syncRecentBankSms(List<String> selectedBanks) async {
    final hasPermission = await requestSmsPermission();
    if (!hasPermission) {
      debugPrint("SMS Permission Denied!");
      return;
    }

    final List<String> targetSenderIds = [];
    if (selectedBanks.contains('boc')) targetSenderIds.addAll(['BOC', 'BOC_SMS', 'BOC_ALERT']);
    if (selectedBanks.contains('nsb')) targetSenderIds.addAll(['NSB', 'NSB_SMS']);
    if (selectedBanks.contains('peoples')) targetSenderIds.addAll(['PEOPLES', 'PEOPLES_BNK']);

    if (targetSenderIds.isEmpty) {
      debugPrint("No supported banks selected.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sms_sync_time');
    DateTime fetchFrom = lastSyncStr != null
        ? DateTime.parse(lastSyncStr)
        : DateTime.now().subtract(const Duration(days: 30));

    final messages = await _query.querySms(kinds: [SmsQueryKind.inbox], sort: true);
    DateTime? newestSmsDate;

    for (var msg in messages) {
      final sender = msg.sender?.toUpperCase() ?? '';

      bool isTargetBank = targetSenderIds.any((target) => sender.contains(target));

      if (isTargetBank && msg.date != null && msg.date!.isAfter(fetchFrom)) {
        await _parseAndSaveMessage(msg);

        if (newestSmsDate == null || msg.date!.isAfter(newestSmsDate!)) {
          newestSmsDate = msg.date;
        }
      }
    }

    if (newestSmsDate != null) {
      await prefs.setString('last_sms_sync_time', newestSmsDate.toIso8601String());
      debugPrint("✅ Sync Complete. New cursor set to: $newestSmsDate");
    } else {
      debugPrint("✅ No new SMS found.");
    }
  }

  Future<int> _getOrCreateAccount(String senderName) async {
    final accounts = await _accDao.watchAllAccounts().first;
    final existingMatches = accounts.where((a) => a.name.toUpperCase() == senderName.toUpperCase());
    if (existingMatches.isNotEmpty) return existingMatches.first.id;

    return await _accDao.insertAccount(
        AccountsCompanion.insert(name: senderName, type: 'bank', initialBalance: const drift.Value(0.0))
    );
  }

  Future<int> _getCashWalletId() async {
    final accounts = await _accDao.watchAllAccounts().first;
    final cashWallets = accounts.where((a) => a.type == 'cash' || a.name.toUpperCase() == 'MY WALLET');
    if (cashWallets.isNotEmpty) return cashWallets.first.id;

    return await _accDao.insertAccount(
        AccountsCompanion.insert(name: 'My Wallet', type: 'cash', initialBalance: const drift.Value(0.0))
    );
  }

  Future<int> _getOrCreateCategory(String categoryName, bool isIncome) async {
    final cats = await _catDao.watchCategories(isIncome).first;
    final existingMatches = cats.where((c) => c.name.toUpperCase() == categoryName.toUpperCase());
    if (existingMatches.isNotEmpty) return existingMatches.first.id;

    return await _catDao.insertCategory(
        CategoriesCompanion.insert(name: categoryName, isIncome: isIncome, icon: const drift.Value('category'))
    );
  }

  Future<void> _parseAndSaveMessage(SmsMessage msg) async {
    final body = msg.body ?? '';
    final sender = msg.sender ?? '';
    final msgDate = msg.date ?? DateTime.now();

    if (RegExp(r'^[A-Za-z]+$').hasMatch(sender) || sender.toUpperCase().contains('BANK')) {
      final amountMatch = _amountRegex.firstMatch(body);

      if (amountMatch != null) {
        final amountStr = amountMatch.group(1)?.replaceAll(',', '');
        final amount = double.tryParse(amountStr ?? '0') ?? 0;

        final isExpense = _debitRegex.hasMatch(body);
        final isIncome = _creditRegex.hasMatch(body);

        if (isExpense || isIncome) {
          final isTxIncome = isIncome;
          final finalAmount = isTxIncome ? amount : -amount;
          final accId = await _getOrCreateAccount(sender);

          String rawDescription = 'SMS: $sender';
          if (body.contains('POS') || body.contains('ATM')) {
            final atMatch = RegExp(r'at\s+([^).]+)').firstMatch(body);
            if (atMatch != null) rawDescription = atMatch.group(1)?.trim() ?? rawDescription;
          }

          final normalizedDesc = _normalizeText(rawDescription);

          bool isAtm = !isTxIncome &&
              (body.toUpperCase().contains('ATM') || normalizedDesc.contains('ATM')) &&
              !_atmNoiseRegex.hasMatch(body);

          if (isAtm) {
            final cashWalletId = await _getCashWalletId();
            final isDuplicate = await _txDao.isTransactionExists(amount, rawDescription, msgDate);

            if (!isDuplicate) {
              await _txDao.addTransfer(
                fromAccountId: accId,
                toAccountId: cashWalletId,
                amount: amount,
                note: rawDescription,
                date: msgDate,
              );
              debugPrint("✅ SAVED TRANSFER [ATM]: Rs. $amount ($rawDescription)");
            }
          } else {
            String predictedCategoryName = 'Uncategorized';
            int? predictedCatId;

            if (isTxIncome) {
              predictedCategoryName = 'Income (Other)';
            } else {
              final dbRules = await _ruleDao.getAllRulesSorted();
              bool ruleMatched = false;
              for (var rule in dbRules) {
                if (normalizedDesc.contains(rule.merchantKey)) {
                  predictedCatId = rule.categoryId;
                  await _ruleDao.incrementMatchCount(rule.merchantKey);
                  ruleMatched = true;
                  break;
                }
              }

              if (!ruleMatched) {
                for (var entry in _tier2Regex.entries) {
                  if (entry.key.hasMatch(normalizedDesc)) {
                    predictedCategoryName = entry.value;
                    break;
                  }
                }
              }
            }

            final catId = predictedCatId ?? await _getOrCreateCategory(predictedCategoryName, isTxIncome);
            final isDuplicate = await _txDao.isTransactionExists(finalAmount, rawDescription, msgDate);

            if (!isDuplicate) {
              final transaction = TransactionsCompanion.insert(
                description: rawDescription,
                amount: finalAmount,
                date: msgDate,
                accountId: accId,
                categoryId: drift.Value(catId),
                isRefund: const drift.Value(false),
              );

              await _txDao.addTransactionAndUpdateBalance(transaction, accId);
              debugPrint("✅ SAVED TO [$sender]: Rs. $amount ($rawDescription)");
            }
          }
        }
      }
    }
  }
}