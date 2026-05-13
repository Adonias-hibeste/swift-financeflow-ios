enum TransactionType { incoming, outgoing }

class FinanceTransaction {
  final String title;
  final String category;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? subtitle;

  FinanceTransaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.subtitle,
  });
}

class WalletBalance {
  final double total;
  final double income;
  final double spending;
  final double monthlyChangePercent;

  WalletBalance({
    required this.total,
    required this.income,
    required this.spending,
    required this.monthlyChangePercent,
  });
}
