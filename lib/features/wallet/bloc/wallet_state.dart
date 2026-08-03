import '../models/wallet_model.dart';

class WalletState {
  final bool isLoading;
  final String? error;
  final Wallet? wallet;
  final List<Transaction> transactions;
  final String? paymobPaymentKey;
  final String? paymobOrderId;
  final bool depositSuccess;
  final double lastDepositAmount;
  final List<BankCard>? cards;

  const WalletState({
    this.isLoading = false,
    this.error,
    this.wallet,
    this.transactions = const [],
    this.paymobPaymentKey,
    this.paymobOrderId,
    this.depositSuccess = false,
    this.lastDepositAmount = 0,
    this.cards,
  });

  WalletState copyWith({
    bool? isLoading,
    String? error,
    Wallet? wallet,
    List<Transaction>? transactions,
    String? paymobPaymentKey,
    String? paymobOrderId,
    bool? depositSuccess,
    double? lastDepositAmount,
    List<BankCard>? cards,
    bool clearError = false,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      paymobPaymentKey: paymobPaymentKey ?? this.paymobPaymentKey,
      paymobOrderId: paymobOrderId ?? this.paymobOrderId,
      depositSuccess: depositSuccess ?? this.depositSuccess,
      lastDepositAmount: lastDepositAmount ?? this.lastDepositAmount,
      cards: cards ?? this.cards,
    );
  }
}
