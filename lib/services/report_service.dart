import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

/// Handles all Firestore operations for the report feature.
class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submits a new report to the [reports] collection.
  Future<void> submitReport(ReportModel report) async {
    try {
      await _db.collection('reports').add(report.toJson());
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('Failed to submit report: $e'), st);
    }
  }

  /// Real-time stream of all reports with status 'pending', newest first.
  /// Only accessible by admins (enforced by Firestore rules).
  Stream<List<ReportModel>> watchPendingReports() {
    return _db
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ReportModel.fromJson(d.data(), d.id)).toList(),
        );
  }

  /// Updates the status of a report ('reviewed' or 'dismissed').
  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _db.collection('reports').doc(reportId).update({'status': status});
    } catch (e, st) {
      Error.throwWithStackTrace(
        Exception('Failed to update report status: $e'),
        st,
      );
    }
  }
}
