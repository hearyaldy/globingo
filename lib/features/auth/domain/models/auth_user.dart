class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isEmailVerified;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.isEmailVerified,
  });
}
