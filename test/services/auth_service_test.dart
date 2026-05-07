
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cerebrosim/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockFirebaseFunctions mockFunctions;
  late AuthService authService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockFunctions = MockFirebaseFunctions();
    authService = AuthService(
      auth: mockAuth,
      googleSignIn: mockGoogleSignIn,
      functions: mockFunctions,
    );
  });

  group('AuthService Tests', () {
    test('signOut() should call signOut on both FirebaseAuth and GoogleSignIn', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      await authService.signOut();

      verify(() => mockAuth.signOut()).called(1);
      verify(() => mockGoogleSignIn.signOut()).called(1);
    });

    test('deleteAccount() calls deleteUserAccount function and signs out Google', () async {
      final mockUser = MockUser();
      final mockCallable = MockHttpsCallable();

      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockFunctions.httpsCallable('deleteUserAccount'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call<void>(null))
          .thenAnswer((_) async => MockHttpsCallableResult());
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      await authService.deleteAccount();

      verify(() => mockFunctions.httpsCallable('deleteUserAccount')).called(1);
      verify(() => mockCallable.call<void>(null)).called(1);
      verify(() => mockGoogleSignIn.signOut()).called(1);
    });

    test('deleteAccount() does nothing when no user is signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      await authService.deleteAccount();

      verifyNever(() => mockFunctions.httpsCallable(any()));
      verifyNever(() => mockGoogleSignIn.signOut());
    });
  });
}

class MockUser extends Mock implements User {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult extends Mock implements HttpsCallableResult<void> {}
