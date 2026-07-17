abstract class AdminEvent {}

class LoadAdminStats extends AdminEvent {}

class LoadDrivers extends AdminEvent {}

class LoadPassengers extends AdminEvent {}

class LoadTrips extends AdminEvent {}

class LoadDriverApplications extends AdminEvent {}

class ApproveDriver extends AdminEvent {
  final String userId;
  ApproveDriver(this.userId);
}

class RejectDriver extends AdminEvent {
  final String userId;
  RejectDriver(this.userId);
}

class ToggleDriverBan extends AdminEvent {
  final String userId;
  final bool banned;
  ToggleDriverBan({required this.userId, required this.banned});
}

class LoadAppSettings extends AdminEvent {}

class UpdateAppSettings extends AdminEvent {
  final Map<String, double> settings;
  UpdateAppSettings(this.settings);
}
