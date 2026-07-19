import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/supabase_config.dart';
import '../repositories/subscription_repository.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _repository;

  SubscriptionBloc({required SubscriptionRepository repository})
      : _repository = repository,
        super(const SubscriptionState()) {
    on<LoadSubscription>(_onLoad);
    on<Subscribe>(_onSubscribe);
    on<CancelSubscription>(_onCancel);
  }

  Future<void> _onLoad(
      LoadSubscription event, Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final sub = await _repository.fetchActiveSubscription(user.id);
      emit(state.copyWith(isLoading: false, activeSubscription: sub));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSubscribe(
      Subscribe event, Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final sub = await _repository.createSubscription(
        userId: user.id,
        tierType: event.tierType,
        price: event.price,
      );
      emit(state.copyWith(
        isLoading: false,
        activeSubscription: sub,
        subscribeSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCancel(
      CancelSubscription event, Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      if (state.activeSubscription != null) {
        await _repository.cancelSubscription(state.activeSubscription!.id);
      }
      emit(state.copyWith(isLoading: false, activeSubscription: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
