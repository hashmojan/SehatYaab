import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthService extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rxn<User> _firebaseUser = Rxn<User>();

  // Current user getter
  User? get currentUser => _firebaseUser.value;
  String? get currentUserId => _firebaseUser.value?.uid;

  @override
  void onInit() {
    super.onInit();
    // Set up auth state changes
    _auth.authStateChanges().listen(_setFirebaseUser);
  }

  void _setFirebaseUser(User? user) {
    _firebaseUser.value = user;
  }

  // Registration with email and password
  Future<String?> registerUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    } catch (e) {
      throw 'An unknown error occurred';
    }
  }

  // Login with email and password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  // Get current user token (for API auth)
  Future<String?> getToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // Helper method to convert Firebase error codes to user-friendly messages
  String _authError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found for this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'weak-password':
        return 'Password is too weak';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return 'An unknown error occurred';
    }
  }
}