/// Named route constants for UniTrade navigation.
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String login = '/auth/login';
  static const String emailVerification = '/auth/verify-email';
  static const String home = '/home';

  // About
  static const String aboutUs = '/about';

  // Listings
  static const String listingDetail = '/listing/detail';
  static const String addListing = '/listing/add';
  static const String departmentListings = '/listing/department';
  static const String allListings = '/listing/all';
  static const String pendingListings = '/listing/pending';

  // Category
  static const String category = '/category';

  // Chat
  static const String chatList = '/chat';
  static const String chatDetail = '/chat/detail';

  // Profile
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String sellerProfile = '/profile/seller';

  // Settings
  static const String settings = '/settings';

  // Subscription
  static const String payment = '/subscription/payment';
  static const String subscribedUsers = '/subscription/subscribers';
}
