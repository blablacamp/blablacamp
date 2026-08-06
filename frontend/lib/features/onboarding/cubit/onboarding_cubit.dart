import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The two entry roles a user picks on onboarding.
/// Mirrors profiles.default_role in the database.
enum UserRole {
  campmate('campmate'),
  campmaker('campmaker');

  const UserRole(this.value);
  final String value;
}

class OnboardingState extends Equatable {
  const OnboardingState({this.selectedRole = UserRole.campmate});

  final UserRole selectedRole;

  OnboardingState copyWith({UserRole? selectedRole}) =>
      OnboardingState(selectedRole: selectedRole ?? this.selectedRole);

  @override
  List<Object?> get props => [selectedRole];
}

/// Holds the role the user is leaning towards on the onboarding screen.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState());

  void selectRole(UserRole role) => emit(state.copyWith(selectedRole: role));
}
