import 'package:equatable/equatable.dart';

enum ReportStatus { submitted, underReview, resolved, dismissed }

extension ReportStatusX on ReportStatus {
  static ReportStatus fromString(String value) {
    switch (value) {
      case 'under_review':
        return ReportStatus.underReview;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.submitted;
    }
  }

  String get label {
    switch (this) {
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.underReview:
        return 'Under review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Closed';
    }
  }
}

class SafetyReport extends Equatable {
  const SafetyReport({
    required this.id,
    required this.reporterId,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.targetProfileId,
    this.category,
    this.description,
    this.resolutionNotes,
  });

  final String id;
  final String reporterId;
  final String? targetProfileId;
  final String? category;
  final String? description;
  final ReportStatus status;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SafetyReport.fromJson(Map<String, dynamic> json) {
    return SafetyReport(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      targetProfileId: json['target_profile_id'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      status: ReportStatusX.fromString(json['status'] as String? ?? 'submitted'),
      resolutionNotes: json['resolution_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, reporterId, status, createdAt];
}

