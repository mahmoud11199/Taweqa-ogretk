import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/supabase_config.dart';
import '../repositories/wallet_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _repository;

  WalletBloc({required WalletRepository repository})
      : _repository = repository,
        super(const WalletState()) {
    on<LoadWallet>(_onLoadWallet);
    on<LoadTransactions>(_onLoadTransactions);
    on<InitDeposit>(_onInitDeposit);
    on<ResetDeposit>(_onResetDeposit);
    on<DeductPayment>(_onDeductPayment);
  }

  Future<void> _onLoadWallet(
      LoadWallet event, Emitter<WalletState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final wallet = await _repository.fetchWallet(user.id);
      emit(state.copyWith(isLoading: false, wallet: wallet, depositSuccess: false));
      add(LoadTransactions());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadTransactions(
      LoadTransactions event, Emitter<WalletState> emit) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith()); return; }
      final transactions = await _repository.fetchTransactions(user.id);
      emit(state.copyWith(transactions: transactions));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onInitDeposit(
      InitDeposit event, Emitter<WalletState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false, error: 'المستخدم غير موجود')); return; }
      final id = await _repository.createPendingDeposit(
        userId: user.id,
        amount: event.amount,
        senderPhone: event.senderPhone,
      );
      emit(state.copyWith(
        isLoading: false,
        depositSubmitted: true,
        pendingDepositId: id,
        lastDepositAmount: event.amount,
        lastSenderPhone: event.senderPhone,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onResetDeposit(
      ResetDeposit event, Emitter<WalletState> emit) async {
    emit(state.copyWith(
      depositSubmitted: false,
      pendingDepositId: null,
      depositSuccess: false,
    ));
  }

  Future<void> _onDeductPayment(
      DeductPayment event, Emitter<WalletState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      await _repository.deductFare(user.id, event.amount, event.tripId);
      final wallet = await _repository.fetchWallet(user.id);
      emit(state.copyWith(isLoading: false, wallet: wallet));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}