class AuthUser {
  const AuthUser(this.uid, this.email);
  final String uid;
  final String? email;
}

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}
