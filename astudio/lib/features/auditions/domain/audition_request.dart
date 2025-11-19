import 'package:equatable/equatable.dart';

enum AuditionStatus { pending, confirmed, submitted, reviewed, cancelled }

extension AuditionStatusX on AuditionStatus {
  static AuditionStatus fromString(String value) {
    return AuditionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AuditionStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case AuditionStatus.pending:
        return 'Pending';
      case AuditionStatus.confirmed:
        return 'Confirmed';
      case AuditionStatus.submitted:
        return 'Submitted';
      case AuditionStatus.reviewed:
        return 'Reviewed';
      case AuditionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class AuditionRequest extends Equatable {
  const AuditionRequest({
    required this.id,
    required this.castingId,
    required this.talentId,
    required this.requestedBy,
    required this.status,
    required this.requestType,
    required this.createdAt,
    required this.updatedAt,
    this.applicationId,
    this.instructions,
    this.meetingLink,
    this.scheduledAt,
    this.dueDate,
    this.submissionUrl,
    this.reviewerNotes,
    this.talentName,
    this.castingTitle,
  });

  final String id;
  final String castingId;
  final String talentId;
  final String requestedBy;
  final String? applicationId;
  final AuditionStatus status;
  final String requestType;
  final String? instructions;
  final String? meetingLink;
  final DateTime? scheduledAt;
  final DateTime? dueDate;
  final String? submissionUrl;
  final String? reviewerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? talentName;
  final String? castingTitle;

  bool get isOverdue =>
      dueDate != null &&
      submissionUrl == null &&
      dueDate!.isBefore(DateTime.now());

  AuditionRequest copyWith({
    AuditionStatus? status,
    String? submissionUrl,
    String? reviewerNotes,
  }) {
    return AuditionRequest(
      id: id,
      castingId: castingId,
      talentId: talentId,
      requestedBy: requestedBy,
      applicationId: applicationId,
      status: status ?? this.status,
      requestType: requestType,
      instructions: instructions,
      meetingLink: meetingLink,
      scheduledAt: scheduledAt,
      dueDate: dueDate,
      submissionUrl: submissionUrl ?? this.submissionUrl,
      reviewerNotes: reviewerNotes ?? this.reviewerNotes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      talentName: talentName,
      castingTitle: castingTitle,
    );
  }

  factory AuditionRequest.fromJson(Map<String, dynamic> json) {
    return AuditionRequest(
      id: json['id'] as String,
      castingId: json['casting_id'] as String,
      talentId: json['talent_id'] as String,
      requestedBy: json['requested_by'] as String,
      applicationId: json['application_id'] as String?,
      status: AuditionStatusX.fromString(json['status'] as String? ?? 'pending'),
      requestType: json['request_type'] as String? ?? 'self_tape',
      instructions: json['instructions'] as String?,
      meetingLink: json['meeting_link'] as String?,
      scheduledAt: _parseDate(json['scheduled_at']),
      dueDate: _parseDate(json['due_date']),
      submissionUrl: json['submission_url'] as String?,
      reviewerNotes: json['reviewer_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      talentName: json['talent_name'] as String?,
      castingTitle: json['casting_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'casting_id': castingId,
      'talent_id': talentId,
      'requested_by': requestedBy,
      'application_id': applicationId,
      'status': status.name,
      'request_type': requestType,
      'instructions': instructions,
      'meeting_link': meetingLink,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'submission_url': submissionUrl,
      'reviewer_notes': reviewerNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'talent_name': talentName,
      'casting_title': castingTitle,
    };
  }

  @override
  List<Object?> get props => [id, status, talentId, castingId, submissionUrl];
}

DateTime? _parseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

