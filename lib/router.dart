import 'package:flutter/material.dart';
import 'models/product_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/about/about_us_screen.dart';
import 'screens/about/campus_safety_guide_screen.dart';
import 'screens/listing/listing_detail_screen.dart';
import 'screens/listing/add_listing_screen.dart';
import 'screens/listing/edit_listing_screen.dart';
import 'screens/listing/all_listings_screen.dart';
import 'screens/listing/department_listings_screen.dart';
import 'screens/listing/favourite_listings_screen.dart';
import 'screens/listing/pending_listings_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/seller_profile_screen.dart';
import 'screens/category_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/subscription/payment_screen.dart';
import 'screens/subscription/subscribed_users_screen.dart';
import 'constants/app_routes.dart';
import 'data/dummy_categories.dart';

/// Central router — all named routes are registered here.
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case AppRoutes.emailVerification:
        return MaterialPageRoute(
          builder: (_) => const EmailVerificationScreen(),
        );

      case AppRoutes.login:
        // Optional argument 'register' opens the form in register mode
        final arg = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => LoginScreen(
            initialMode: arg == 'register'
                ? LoginMode.register
                : LoginMode.login,
          ),
        );

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.aboutUs:
        return MaterialPageRoute(builder: (_) => const AboutUsScreen());

      case AppRoutes.campusSafetyGuide:
        return MaterialPageRoute(
          builder: (_) => const CampusSafetyGuideScreen(),
        );

      case AppRoutes.listingDetail:
        final productId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ListingDetailScreen(productId: productId),
        );

      case AppRoutes.addListing:
        return MaterialPageRoute(builder: (_) => const AddListingScreen());

      case AppRoutes.editListing:
        final product = settings.arguments as ProductModel;
        return MaterialPageRoute(
          builder: (_) => EditListingScreen(product: product),
        );

      case AppRoutes.offersListings:
        return MaterialPageRoute(
          builder: (_) => const AllListingsScreen(offersOnly: true),
        );

      case AppRoutes.departmentListings:
        final category = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => DepartmentListingsScreen(category: category),
        );

      case AppRoutes.category:
        final categoryName = settings.arguments as String? ?? '';
        final category = dummyCategories.firstWhere(
          (item) => item.name == categoryName,
          orElse: () => dummyCategories.first,
        );
        return MaterialPageRoute(
          builder: (_) => CategoryScreen(category: category),
        );

      case AppRoutes.allListings:
        final initialCategory = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => AllListingsScreen(initialCategory: initialCategory),
        );

      case AppRoutes.pendingListings:
        return MaterialPageRoute(builder: (_) => const PendingListingsScreen());

      case AppRoutes.favouriteListings:
        return MaterialPageRoute(
          builder: (_) => const FavouriteListingsScreen(),
        );

      case AppRoutes.chatList:
        return MaterialPageRoute(builder: (_) => const ChatListScreen());

      case AppRoutes.chatDetail:
        final conversationId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ChatDetailScreen(conversationId: conversationId),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case AppRoutes.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case AppRoutes.sellerProfile:
        final uid = settings.arguments as String? ?? '';
        return MaterialPageRoute(builder: (_) => SellerProfileScreen(uid: uid));

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppRoutes.payment:
        return MaterialPageRoute(builder: (_) => const PaymentScreen());

      case AppRoutes.subscribedUsers:
        return MaterialPageRoute(builder: (_) => const SubscribedUsersScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
