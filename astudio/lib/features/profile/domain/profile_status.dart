enum ProfileStatus {
  pending,
  approved,
  rejected,
  suspended;

  static ProfileStatus fromString(String value) {
    return ProfileStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ProfileStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case ProfileStatus.pending:
        return 'Pending Approval';
      case ProfileStatus.approved:
        return 'Approved';
      case ProfileStatus.rejected:
        return 'Rejected';
      case ProfileStatus.suspended:
        return 'Suspended';
    }
  }

  bool get isAwaitingReview => this == ProfileStatus.pending;
  bool get isActive => this == ProfileStatus.approved;
  bool get isRejected => this == ProfileStatus.rejected;
  bool get isSuspended => this == ProfileStatus.suspended;
}
