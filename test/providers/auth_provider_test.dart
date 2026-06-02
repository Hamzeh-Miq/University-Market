import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_market/models/user_model.dart';
import 'package:university_market/providers/auth_provider.dart';

void main() {
  group('hasActiveSubscriptionProvider', () {
    ProviderContainer createContainer(UserModel? user) {
      return ProviderContainer(
        overrides: [
          currentUserModelProvider.overrideWith((ref) => Stream.value(user)),
        ],
      );
    }

    test('returns true when subscription is active and unexpired', () async {
      final container = createContainer(
        UserModel(
          uid: '1',
          email: 'student@students.asu.edu.jo',
          firstName: 'Test',
          lastName: 'User',
          phoneNumber: '0790000000',
          university: 'Applied Science Private University',
          isVerified: true,
          createdAt: DateTime(2026, 1, 1),
          isSubscribed: true,
          subscriptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
        ),
      );
      addTearDown(container.dispose);

      await container.read(currentUserModelProvider.future);
      expect(container.read(hasActiveSubscriptionProvider), isTrue);
    });

    test('returns false when subscription is expired', () async {
      final container = createContainer(
        UserModel(
          uid: '1',
          email: 'student@students.asu.edu.jo',
          firstName: 'Test',
          lastName: 'User',
          phoneNumber: '0790000000',
          university: 'Applied Science Private University',
          isVerified: true,
          createdAt: DateTime(2026, 1, 1),
          isSubscribed: true,
          subscriptionExpiresAt: DateTime.now().subtract(
            const Duration(days: 1),
          ),
        ),
      );
      addTearDown(container.dispose);

      await container.read(currentUserModelProvider.future);
      expect(container.read(hasActiveSubscriptionProvider), isFalse);
    });

    test('returns false when subscription flag is off', () async {
      final container = createContainer(
        UserModel(
          uid: '1',
          email: 'student@students.asu.edu.jo',
          firstName: 'Test',
          lastName: 'User',
          phoneNumber: '0790000000',
          university: 'Applied Science Private University',
          isVerified: true,
          createdAt: DateTime(2026, 1, 1),
          isSubscribed: false,
          subscriptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
        ),
      );
      addTearDown(container.dispose);

      await container.read(currentUserModelProvider.future);
      expect(container.read(hasActiveSubscriptionProvider), isFalse);
    });
  });
}
