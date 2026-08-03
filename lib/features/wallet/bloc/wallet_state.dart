import '../models/wallet_model.dart';

class WalletState {
  final bool isLoading;
  final String? error;
  final Wallet? wallet;
  final List<Transaction> transactions;
  final bool depositSubmitted;
  final String? pendingDepositId;
  final bool depositSuccess;
  final double lastDepositAmount;
  final String? lastSenderPhone;

  const WalletState({
    this.isLoading = false,
    this.error,
    this.wallet,
    this.transactions = const [],
    this.depositSubmitted = false,
    this.pendingDepositId,
    this.depositSuccess = false,
    this.lastDepositAmount = 0,
    this.lastSenderPhone,
  });

  WalletState copyWith({
    bool? isLoading,
    String? error,
    Wallet? wallet,
    List<Transaction>? transactions,
    bool? depositSubmitted,
    String? pendingDepositId,
    bool? depositSuccess,
    double? lastDepositAmount,
    String? lastSenderPhone,
    bool clearError = false,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      depositSubmitted: depositSubmitted ?? this.depositSubmitted,
      pendingDepositId: pendingDepositId ?? this.pendingDepositId,
      depositSuccess: depositSuccess ?? this.depositSuccess,
      lastDepositAmount: lastDepositAmount ?? this.lastDepositAmount,
      lastSenderPhone: lastSenderPhone ?? this.lastSenderPhone,
    );
  }
}