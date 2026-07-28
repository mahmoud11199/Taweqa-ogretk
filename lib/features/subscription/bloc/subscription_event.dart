abstract class SubscriptionEvent {}

class LoadSubscription extends SubscriptionEvent {}

class Subscribe extends SubscriptionEvent {
  final String planType;
  Subscribe({required this.planType});
}

class CancelSubscription extends SubscriptionEvent {}
