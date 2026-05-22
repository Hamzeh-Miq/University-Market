import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

/// Singleton [ReportService] provider.
final reportServiceProvider =
    Provider<ReportService>((ref) => ReportService());

/// Real-time stream of all pending reports.
/// Only resolves successfully for admin users (Firestore rules enforce this).
final pendingReportsProvider =
    StreamProvider.autoDispose<List<ReportModel>>(
  (ref) => ref.watch(reportServiceProvider).watchPendingReports(),
);
