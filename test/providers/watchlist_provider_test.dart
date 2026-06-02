import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_market/models/user_model.dart';
import 'package:university_market/providers/auth_provider.dart';
import 'package:university_market/providers/watchlist_provider.dart';

void main() {
  group('watchlistProvider', () {
    ProviderContainer createContainer(List<String> favoriteProductIds) {
      final user = UserModel(
        uid: '1',
        email: 'student@students.asu.edu.jo',
        firstName: 'Test',
        lastName: 'User',
        phoneNumber: '0790000000',
        university: 'Applied Science Private University',
        isVerified: true,
        createdAt: DateTime(2026, 1, 1),
        favoriteProductIds: favoriteProductIds,
      );

      return ProviderContainer(
        overrides: [
          currentUserModelProvider.overrideWith((ref) => Stream.value(user)),
        ],
      );
    }

    test('reads favorite product IDs from the current user profile', () async {
      final container = createContainer(['p1', 'p2']);
      addTearDown(container.dispose);

      await container.read(currentUserModelProvider.future);

      expect(container.read(watchlistProvider), ['p1', 'p2']);
    });

    test('counts unique favorite product IDs', () async {
      final container = createContainer(['p1', 'p1', 'p2']);
      addTearDown(container.dispose);

      await container.read(currentUserModelProvider.future);

      expect(container.read(favoriteCountProvider), 2);
    });
  });
}
