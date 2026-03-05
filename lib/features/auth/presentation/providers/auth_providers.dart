import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final bool learningModeEnabled;
  final bool teachingModeEnabled;
  final String activeMode;
  final String? rolePreference;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    required this.learningModeEnabled,
    required this.teachingModeEnabled,
    required this.activeMode,
    this.rolePreference,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      learningModeEnabled: (data['learningModeEnabled'] as bool?) ?? true,
      teachingModeEnabled: (data['teachingModeEnabled'] as bool?) ?? false,
      activeMode: (data['activeMode'] as String?) ?? 'learning',
      rolePreference: data['rolePreference'] as String?,
    );
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseFirestoreProvider),
  );
});

final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentAuthUserProvider = Provider<AuthUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull;
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  final uid = firebaseAuth.currentUser?.uid;
  if (uid == null) {
    return Stream.value(null);
  }

  return firestore.collection('users').doc(uid).snapshots().map((snapshot) {
    if (!snapshot.exists) return null;
    return UserProfile.fromMap(uid, snapshot.data() ?? const {});
  });
});

final isAdminUserProvider = StreamProvider<bool>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);

  return firebaseAuth.idTokenChanges().asyncMap((user) async {
    if (user == null) {
      return false;
    }
    try {
      final token = await user.getIdTokenResult();
      return token.claims?['admin'] == true;
    } catch (_) {
      return false;
    }
  });
});

class AuthController {
  AuthController(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> signIn({required String email, required String password}) {
    return _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _repository.createUserWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  Future<void> resetPassword(String email) {
    return _repository.sendPasswordResetEmail(email);
  }

  Future<void> signOut() {
    return _repository.signOut();
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
