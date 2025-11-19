import 'package:equatable/equatable.dart';

enum VerificationStatus { pending, approved, rejected }

extension VerificationStatusX on VerificationStatus {
  static VerificationStatus fromString(String value) {
    return VerificationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => VerificationStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending review';
      case VerificationStatus.approved:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }
}

class IdentityVerificationRequest extends Equatable {
  const IdentityVerificationRequest({
    required this.id,
    required this.profileId,
    required this.documentUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.documentType,
    this.reviewerNotes,
  });

  final String id;
  final String profileId;
  final String documentUrl;
  final VerificationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? documentType;
  final String? reviewerNotes;

  factory IdentityVerificationRequest.fromJson(Map<String, dynamic> json) {
    return IdentityVerificationRequest(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      documentUrl: json['document_url'] as String,
      status: VerificationStatusX.fromString(
        json['status'] as String? ?? 'pending',
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      documentType: json['document_type'] as String?,
      reviewerNotes: json['reviewer_notes'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, profileId, status, documentUrl, createdAt, updatedAt];
}

