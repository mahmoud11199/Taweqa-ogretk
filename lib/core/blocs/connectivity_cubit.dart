import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/sync_service.dart';

class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit() : super(true) {
    SyncService.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged(bool online) {
    if (online != state) {
      emit(online);
    }
  }

  @override
  Future<void> close() {
    SyncService.removeListener(_onConnectivityChanged);
    return super.close();
  }
}
