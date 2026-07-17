import '../models/wallet_model.dart';

class WalletState {
  final bool isLoading;
  final String? error;
  final Wallet? wallet;
  final List<Transaction> transactions;
  final String? paymobPaymentKey;
  final bool depositSuccess;

  const WalletState({
    this.isLoading = false,
    this.error,
    this.wallet,
    this.transactions = const [],
    this.paymobPaymentKey,
    this.depositSuccess = false,
  });

  WalletState copyWith({
    bool? isLoading,
    String? error,
    Wallet? wallet,
    List<Transaction>? transactions,
    String? paymobPaymentKey,
    bool? depositSuccess,
    bool clearError = false,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      paymobPaymentKey: paymobPaymentKey ?? this.paymobPaymentKey,
      depositSuccess: depositSuccess ?? this.depositSuccess,
    );
  }
}
