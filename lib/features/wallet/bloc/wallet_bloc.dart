import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/supabase_config.dart';
import '../models/wallet_model.dart';
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
    on<VerifyDeposit>(_onVerifyDeposit);
    on<DeductPayment>(_onDeductPayment);
    on<LoadCards>(_onLoadCards);
    on<SaveCard>(_onSaveCard);
    on<DeleteCard>(_onDeleteCard);
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
    emit(state.copyWith(isLoading: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final paymentKey = await _repository.initPaymobPayment(
        userId: user.id,
        amount: event.amount,
        email: event.email,
        phone: event.phone,
        method: event.method,
      );
      emit(state.copyWith(isLoading: false, paymobPaymentKey: paymentKey, lastDepositAmount: event.amount));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onVerifyDeposit(
      VerifyDeposit event, Emitter<WalletState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final success = await _repository.verifyPaymobPayment(event.transactionRef);
      if (success) {
        final user = SupabaseConfig.client.auth.currentUser;
        if (user != null) {
          await _repository.recordDeposit(
            userId: user.id,
            amount: state.lastDepositAmount,
            paymobRef: event.transactionRef,
          );
          final wallet = await _repository.fetchWallet(user.id);
          emit(state.copyWith(
            isLoading: false,
            wallet: wallet,
            depositSuccess: true,
            paymobPaymentKey: null,
          ));
        } else {
          emit(state.copyWith(isLoading: false, error: 'المستخدم غير موجود'));
        }
      } else {
        emit(state.copyWith(isLoading: false, error: 'فشلت عملية الدفع'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
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

  Future<void> _onLoadCards(
      LoadCards event, Emitter<WalletState> emit) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final cards = await _repository.fetchCards(user.id);
      emit(state.copyWith(cards: cards));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSaveCard(
      SaveCard event, Emitter<WalletState> emit) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final card = BankCard(
        id: '', userId: user.id,
        cardHolder: event.cardHolder, last4: event.last4,
        brand: event.brand, expMonth: event.expMonth, expYear: event.expYear,
      );
      await _repository.saveCard(user.id, card);
      final cards = await _repository.fetchCards(user.id);
      emit(state.copyWith(cards: cards));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteCard(
      DeleteCard event, Emitter<WalletState> emit) async {
    try {
      await _repository.deleteCard(event.cardId);
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        final cards = await _repository.fetchCards(user.id);
        emit(state.copyWith(cards: cards));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
