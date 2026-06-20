class BankTransaction {
  final String bankName;
  final double amount;
  final bool isIncome;
  final String accountNo;
  final String? merchant;
  final bool isAtmWithdrawal;
  final DateTime? date;
  final String? rawBody;

  BankTransaction({
    required this.bankName,
    required this.amount,
    required this.isIncome,
    required this.accountNo,
    this.merchant,
    this.isAtmWithdrawal = false,
    this.date,
    this.rawBody,
  });

  // පරීක්ෂා කිරීමේ පහසුව සඳහා (For debugging purposes)
  @override
  String toString() {
    return 'BankTransaction(bank: $bankName, amount: $amount, isIncome: $isIncome, account: $accountNo, merchant: $merchant, isAtm: $isAtmWithdrawal)';
  }
}