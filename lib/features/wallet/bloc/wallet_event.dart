abstract class WalletEvent {}

class LoadWallet extends WalletEvent {}

class LoadTransactions extends WalletEvent {}

class InitDeposit extends WalletEvent {
  final double amount;
  final String senderPhone;
  InitDeposit({
    required this.amount,
    required this.senderPhone,
  });
}

class ResetDeposit extends WalletEvent {}

class DeductPayment extends WalletEvent {
  final double amount;
  final String tripId;
  DeductPayment({required this.amount, required this.tripId});
}