import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

abstract final class SignInService {
  static Future<UserCredential> withApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );
    return FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  static Future<UserCredential> withGoogle() async {
    final account = await GoogleSignIn().signIn();
    if (account == null) throw const _SignInCancelledException();
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<UserCredential> withEmail({
    required String email,
    required String password,
    required bool isSignUp,
  }) async {
    final auth = FirebaseAuth.instance;
    if (isSignUp) {
      return auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }
}

class _SignInCancelledException implements Exception {
  const _SignInCancelledException();
  @override
  String toString() => 'Sign-in cancelled';
}
