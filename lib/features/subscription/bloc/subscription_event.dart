abstract class SubscriptionEvent {}

class LoadSubscription extends SubscriptionEvent {}

class Subscribe extends SubscriptionEvent {
  final String tierType;
  final double price;
  Subscribe({required this.tierType, required this.price});
}

class CancelSubscription extends SubscriptionEvent {}
