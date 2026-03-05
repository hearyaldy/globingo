// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globingo/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class FakeSetOptions extends Fake implements SetOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSetOptions());
  });

  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockUserDoc;
  late FirebaseAuthRepository repository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUsersCollection = MockCollectionReference();
    mockUserDoc = MockDocumentReference();

    when(
      () => mockFirestore.collection('users'),
    ).thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);
    when(() => mockUserDoc.set(any())).thenAnswer((_) async {});
    when(() => mockUserDoc.set(any(), any())).thenAnswer((_) async {});

    repository = FirebaseAuthRepository(mockAuth, mockFirestore);
  });

  group('authStateChanges', () {
    test('maps authenticated user to AuthUser', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('u1');
      when(() => mockUser.email).thenReturn('u1@example.com');
      when(() => mockUser.displayName).thenReturn('User One');
      when(() => mockUser.emailVerified).thenReturn(true);

      when(
        () => mockAuth.authStateChanges(),
      ).thenAnswer((_) => Stream<User?>.value(mockUser));

      final result = await repository.authStateChanges().first;

      expect(result, isNotNull);
      expect(result!.uid, 'u1');
      expect(result.email, 'u1@example.com');
      expect(result.displayName, 'User One');
      expect(result.isEmailVerified, isTrue);
    });

    test('maps null auth state to null', () async {
      when(
        () => mockAuth.authStateChanges(),
      ).thenAnswer((_) => Stream<User?>.value(null));

      final result = await repository.authStateChanges().first;

      expect(result, isNull);
    });
  });

  group('signInWithEmailAndPassword', () {
    test(
      'returns auth user and merges profile update when doc exists',
      () async {
        final mockCredential = MockUserCredential();
        final mockUser = MockUser();
        final mockSnapshot = MockDocumentSnapshot();

        when(
          () => mockAuth.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => mockCredential);
        when(() => mockCredential.user).thenReturn(mockUser);

        when(() => mockUser.uid).thenReturn('u1');
        when(() => mockUser.email).thenReturn('user@example.com');
        when(() => mockUser.displayName).thenReturn('User One');
        when(() => mockUser.photoURL).thenReturn('https://photo');
        when(() => mockUser.emailVerified).thenReturn(false);

        when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);

        final result = await repository.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(result.uid, 'u1');
        expect(result.email, 'user@example.com');
        verify(() => mockUserDoc.set(any(), any())).called(1);
      },
    );

    test('throws when credential has null user', () async {
      final mockCredential = MockUserCredential();
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockCredential);
      when(() => mockCredential.user).thenReturn(null);

      expect(
        () => repository.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  group('createUserWithEmailAndPassword', () {
    test('creates profile doc for new user and updates display name', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();
      final mockSnapshot = MockDocumentSnapshot();

      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: 'new@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockCredential);
      when(() => mockCredential.user).thenReturn(mockUser);

      when(() => mockUser.uid).thenReturn('u2');
      when(() => mockUser.email).thenReturn('new@example.com');
      when(() => mockUser.displayName).thenReturn('New User');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.emailVerified).thenReturn(false);
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => mockUser.reload()).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      when(() => mockUserDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);

      final result = await repository.createUserWithEmailAndPassword(
        email: 'new@example.com',
        password: 'password123',
        displayName: 'New User',
      );

      expect(result.uid, 'u2');
      verify(() => mockUser.updateDisplayName('New User')).called(1);
      verify(() => mockUserDoc.set(any())).called(1);
    });
  });

  group('pass-through methods', () {
    test('sendPasswordResetEmail delegates to FirebaseAuth', () async {
      when(
        () => mockAuth.sendPasswordResetEmail(email: 'reset@example.com'),
      ).thenAnswer((_) async {});

      await repository.sendPasswordResetEmail('reset@example.com');

      verify(
        () => mockAuth.sendPasswordResetEmail(email: 'reset@example.com'),
      ).called(1);
    });

    test('signOut delegates to FirebaseAuth', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
