import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';

/// Shows a modal bottom sheet that lets the current user report a user,
/// product listing, or review.
///
/// [reporterId]  — UID of the user submitting the report.
/// [targetType]  — 'user', 'product', or 'review'.
/// [targetId]    — UID, productId, or reviewId being reported.
/// [targetName]  — Display label shown in the sheet title.
Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String reporterId,
  required String targetType,
  required String targetId,
  required String targetName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(
      ref: ref,
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  final WidgetRef ref;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String targetName;

  const _ReportSheet({
    required this.ref,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.targetName,
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _selectedReason;
  final TextEditingController _descController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  List<String> get _reasons {
    switch (widget.targetType) {
      case 'user':
        return kUserReportReasons;
      case 'review':
        return kReviewReportReasons;
      default:
        return kProductReportReasons;
    }
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a reason.')));
      return;
    }
    setState(() => _submitting = true);

    final report = ReportModel(
      reportId: '',
      reporterId: widget.reporterId,
      targetType: widget.targetType,
      targetId: widget.targetId,
      targetName: widget.targetName,
      reason: _selectedReason!,
      description: _descController.text.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      await widget.ref.read(reportServiceProvider).submitReport(report);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Report submitted. Thank you for keeping UniSooq safe.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  switch (widget.targetType) {
                    'user' => 'Report User',
                    'review' => 'Report Review',
                    _ => 'Report Listing',
                  },
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.targetName,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Reason selection
          const Text(
            'Select a reason:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ..._reasons.map(
            (reason) => RadioListTile<String>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: reason,
              groupValue: _selectedReason,
              onChanged: (v) => setState(() => _selectedReason = v),
              title: Text(
                reason,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 8),

          // Optional description
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Additional details (optional)',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
              ),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _submitting ? 'Submitting…' : 'Submit Report',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
