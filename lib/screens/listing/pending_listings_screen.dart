import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/product_provider.dart';

class PendingListingsScreen extends ConsumerWidget {
  const PendingListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Approvals', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listings) {
          if (listings.isEmpty) {
            return const Center(child: Text('No pending listings.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final product = listings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(product.category),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.listingDetail,
                      arguments: product.productId,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
