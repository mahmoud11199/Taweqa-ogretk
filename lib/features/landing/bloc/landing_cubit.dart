import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/release_info.dart';
import '../repositories/landing_repository.dart';

class LandingState {
  final bool isLoading;
  final ReleaseInfo? release;
  final String? error;
  final String? appVersion;

  const LandingState({
    this.isLoading = true,
    this.release,
    this.error,
    this.appVersion,
  });

  LandingState copyWith({
    bool? isLoading,
    ReleaseInfo? release,
    String? error,
    String? appVersion,
  }) {
    return LandingState(
      isLoading: isLoading ?? this.isLoading,
      release: release ?? this.release,
      error: error,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

class LandingCubit extends Cubit<LandingState> {
  final LandingRepository _repository;

  LandingCubit({required LandingRepository repository})
      : _repository = repository,
        super(const LandingState());

  Future<void> loadRelease() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final release = await _repository.fetchLatestRelease();
      emit(state.copyWith(
        isLoading: false,
        release: release,
        appVersion: release?.version ?? '1.0.0',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
        appVersion: '1.0.0',
      ));
    }
  }
}
