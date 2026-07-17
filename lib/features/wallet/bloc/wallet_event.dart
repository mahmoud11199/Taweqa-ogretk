abstract class WalletEvent {}

class LoadWallet extends WalletEvent {}

class LoadTransactions extends WalletEvent {}

class InitDeposit extends WalletEvent {
  final double amount;
  final String email;
  final String phone;
  InitDeposit({
    required this.amount,
    required this.email,
    required this.phone,
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
