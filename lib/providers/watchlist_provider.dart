import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// Notifier to manage a list of product IDs the user is watching.
class WatchlistNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ref
        .watch(currentUserModelProvider)
        .maybeWhen(
          data: (user) => user?.favoriteProductIds.toSet().toList() ?? [],
          orElse: () => [],
        );
  }

  /// Toggles a product in or out of the watchlist.
  Future<void> toggleItem(String productId) async {
    final user = ref.read(currentUserModelProvider).value;
    if (user == null) return;

    final previousState = state;
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }

    try {
      await ref
          .read(userServiceProvider)
          .updateFavoriteProductIds(user.uid, state);
    } catch (_) {
      state = previousState;
    }
  }

  /// Checks if a product is in the watchlist.
  bool isWatched(String productId) => state.contains(productId);
}

/// Global provider for the Watchlist.
final watchlistProvider = NotifierProvider<WatchlistNotifier, List<String>>(
  WatchlistNotifier.new,
);

/// Count of unique favourite product IDs for notification badges.
final favoriteCountProvider = Provider<int>((ref) {
  return ref.watch(watchlistProvider).toSet().length;
});
