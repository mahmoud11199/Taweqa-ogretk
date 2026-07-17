class Wallet {
  final String userId;
  final double balance;
  final double? pendingBalance;
  final DateTime? lastUpdated;

  Wallet({
    required this.userId,
    required this.balance,
    this.pendingBalance,
    this.lastUpdated,
  });

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      userId: map['user_id'] as String,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      pendingBalance: (map['pending_balance'] as num?)?.toDouble(),
      lastUpdated: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

class Transaction {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final double? balanceBefore;
  final double? balanceAfter;
  final String? description;
  final String status;
  final String? paymobRef;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.balanceBefore,
    this.balanceAfter,
    this.description,
    this.status = 'completed',
    this.paymobRef,
    required this.createdAt,
  });

  bool get isDeposit => type == 'deposit';
  bool get isWithdrawal => type == 'withdrawal';
  bool get isPayment => type == 'payment';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      balanceBefore: (map['balance_before'] as num?)?.toDouble(),
      balanceAfter: (map['balance_after'] as num?)?.toDouble(),
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'completed',
      paymobRef: map['paymob_ref'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

enum TransactionType { deposit, withdrawal, payment }

extension TransactionTypeExtension on TransactionType {
  String get apiValue => name;
  String get label {
    switch (this) {
      case TransactionType.deposit:
        return 'إيداع';
      case TransactionType.withdrawal:
        return 'سحب';
      case TransactionType.payment:
        return 'دفع';
    }
  }
}
