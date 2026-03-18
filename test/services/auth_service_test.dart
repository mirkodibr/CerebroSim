import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockAuthService extends Mock implements AuthService {}
class MockUser extends Mock implements User {}

void main() {
  late MockAuthService mockAuthService;
  late StreamController<User?> authStateController;

  setUp(() {
    mockAuthService = MockAuthService();
    // Using a broadcast stream is key for Riverpod tests
    authStateController = StreamController<User?>.broadcast();
    when(() => mockAuthService.authStateChanges).thenAnswer((_) => authStateController.stream);
  });

  tearDown(() {
    authStateController.close();
  });

  test('authStateProvider should emit null initially', () async {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
    addTearDown(container.dispose);

    // Attach listener to keep provider active
    container.listen(authStateProvider, (_, __) {});

    // Seed null
    authStateController.add(null);

    // Give the stream a moment to propagate
    await pumpEventQueue();

    final userValue = container.read(authStateProvider);
    expect(userValue.value, null);
  });

  test('authStateProvider should emit a User when logged in', () async {
    final mockUser = MockUser();
    
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
    addTearDown(container.dispose);

    // Attach listener to keep provider active
    container.listen(authStateProvider, (_, __) {});

    // Seed mock user
    authStateController.add(mockUser);

    // Give the stream a moment to propagate
    await pumpEventQueue();

    final userValue = container.read(authStateProvider);
    expect(userValue.value, mockUser);
  });
}
