import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier to manage a list of product IDs the user is watching.
class WatchlistNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  /// Toggles a product in or out of the watchlist.
  void toggleItem(String productId) {
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }
  }

  /// Checks if a product is in the watchlist.
  bool isWatched(String productId) => state.contains(productId);
}

/// Global provider for the Watchlist.
final watchlistProvider =
    NotifierProvider<WatchlistNotifier, List<String>>(WatchlistNotifier.new);
