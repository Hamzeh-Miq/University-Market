import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../data/dummy_categories.dart';

/// Static informational page about UniTrade and the university.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'About UniTrade',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded,
                          size: 52, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'University of Jordan',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Mission ────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.flag_rounded,
                    title: 'Our Mission',
                    content:
                        'UniTrade is the exclusive peer-to-peer campus marketplace for University of Jordan students. '
                        'Buy, sell, and trade textbooks, electronics, clothing, and more — safely within your university community.',
                  ),
                  const SizedBox(height: 16),

                  // ── How it works ───────────────────────────────────
                  _SectionCard(
                    icon: Icons.lightbulb_rounded,
                    title: 'How It Works',
                    content:
                        '1. Register with your @students.edu.jo university email.\n'
                        '2. Verify your email to unlock full access.\n'
                        '3. Browse listings by department or search directly.\n'
                        '4. Contact sellers via in-app chat.\n'
                        '5. Post your own listings in seconds.',
                  ),
                  const SizedBox(height: 16),

                  // ── Departments ────────────────────────────────────
                  const Text(
                    'Our Departments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: dummyCategories.length,
                    itemBuilder: (_, i) {
                      final cat = dummyCategories[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: cat.color.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat.icon, color: cat.color, size: 30),
                            const SizedBox(height: 8),
                            Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cat.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Contact ────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.contact_support_rounded,
                    title: 'Contact & Support',
                    content:
                        'Email: support@unitrade.edu.jo\n'
                        'Instagram: @unitrade.jo\n'
                        'Location: University of Jordan, Amman, Jordan',
                  ),
                  const SizedBox(height: 8),

                  // ── Version ────────────────────────────────────────
                  Center(
                    child: Text(
                      'UniTrade v1.0.0 • © 2025 University of Jordan',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable info card section widget.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 6),
                Text(content,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.6,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
