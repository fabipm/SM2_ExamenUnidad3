import '../models/user_profile_model.dart';

/// Estados para la edición del perfil
class EditProfileState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final UserProfileModel? currentProfile;

  const EditProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.currentProfile,
  });

  EditProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    UserProfileModel? currentProfile,
    bool clearError = false,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      currentProfile: currentProfile ?? this.currentProfile,
    );
  }
}
