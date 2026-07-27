abstract class WalletEvent {}

class LoadWallet extends WalletEvent {}

class LoadTransactions extends WalletEvent {}

class InitDeposit extends WalletEvent {
  final double amount;
  final String email;
  final String phone;
  final String method;
  InitDeposit({
    required this.amount,
    required this.email,
    required this.phone,
    this.method = 'card',
  });
}

class VerifyDeposit extends WalletEvent {
  final String transactionRef;
  VerifyDeposit(this.transactionRef);
}

class DeductPayment extends WalletEvent {
  final double amount;
  final String tripId;
  DeductPayment({required this.amount, required this.tripId});
}

class LoadCards extends WalletEvent {}

class SaveCard extends WalletEvent {
  final String cardHolder;
  final String last4;
  final String brand;
  final int expMonth;
  final int expYear;
  SaveCard({
    required this.cardHolder,
    required this.last4,
    required this.brand,
    required this.expMonth,
    required this.expYear,
  });
}

class DeleteCard extends WalletEvent {
  final String cardId;
  DeleteCard(this.cardId);
}
