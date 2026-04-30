import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/listing/listing_detail_screen.dart';
import 'screens/listing/add_listing_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'constants/app_routes.dart';

/// Central router — add all named routes here.
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.listingDetail:
        final productId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ListingDetailScreen(productId: productId),
        );

      case AppRoutes.addListing:
        return MaterialPageRoute(builder: (_) => const AddListingScreen());

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

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
