import '../../../core/models/subscription.dart';

class SubscriptionState {
  final bool isLoading;
  final String? error;
  final Subscription? activeSubscription;
  final bool subscribeSuccess;

  const SubscriptionState({
    this.isLoading = false,
    this.error,
    this.activeSubscription,
    this.subscribeSuccess = false,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    String? error,
    Subscription? activeSubscription,
    bool? subscribeSuccess,
    bool clearError = false,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeSubscription: activeSubscription ?? this.activeSubscription,
      subscribeSuccess: subscribeSuccess ?? this.subscribeSuccess,
    );
  }
}
