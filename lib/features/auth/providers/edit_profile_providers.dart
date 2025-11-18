import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Provider para obtener el perfil completo del usuario desde Firestore
final currentUserProfileProvider = FutureProvider<UserProfileModel?>((
  ref,
) async {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return null;
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .get();

    if (doc.exists && doc.data() != null) {
      return UserProfileModel.fromMap(doc.data()!);
    }

    return null;
  } catch (e) {
    print('Error loading user profile: $e');
    return null;
  }
});
