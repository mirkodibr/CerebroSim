
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cerebrosim/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthService authService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    authService = AuthService(auth: mockAuth, googleSignIn: mockGoogleSignIn);
  });

  group('AuthService Tests', () {
    test('signOut() should call signOut on both FirebaseAuth and GoogleSignIn', () async {
      // Setup mock behaviors
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      // Execute signOut()
      await authService.signOut();

      // Verify that signOut() was called on both services
      verify(() => mockAuth.signOut()).called(1);
      verify(() => mockGoogleSignIn.signOut()).called(1);
    });
  });
}
