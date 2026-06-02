import 'package:cloud_firestore/cloud_firestore.dart';

/// Reason options when reporting a user.
const kUserReportReasons = [
  'Rude / Abusive behavior',
  'Spam',
  'Fake account',
  'Harassment',
  'Other',
];

/// Reason options when reporting a product listing.
const kProductReportReasons = [
  'Item is broken',
  'Does not match photos',
  'Wrong description',
  'Spam listing',
  'Counterfeit / Illegal item',
  'Other',
];

/// Reason options when reporting a profile review.
const kReviewReportReasons = [
  'False or misleading review',
  'Harassment or abusive language',
  'Spam',
  'Off-topic content',
  'Other',
];

/// Represents a report submitted by a user about another user, product, or review.
class ReportModel {
  final String reportId;

  /// UID of the user who submitted the report.
  final String reporterId;

  /// 'user', 'product', or 'review'.
  final String targetType;

  /// UID, productId, or reviewId depending on [targetType].
  final String targetId;

  /// Display name or product title — shown in admin UI.
  final String targetName;

  /// Selected reason from the matching target-type reason list.
  final String reason;

  /// Optional additional details provided by the reporter.
  final String description;

  /// 'pending' | 'reviewed' | 'dismissed'
  final String status;

  final DateTime createdAt;

  ReportModel({
    required this.reportId,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.reason,
    this.description = '',
    this.status = 'pending',
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json, String id) {
    return ReportModel(
      reportId: id,
      reporterId: json['reporterId'] as String? ?? '',
      targetType: json['targetType'] as String? ?? 'user',
      targetId: json['targetId'] as String? ?? '',
      targetName: json['targetName'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'reason': reason,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
