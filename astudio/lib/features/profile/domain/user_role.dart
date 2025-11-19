enum UserRole {
  artist,
  producer,
  admin,
  editor,
  viewer,
  staff;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.artist,
    );
  }

  bool get isStaff =>
      this == UserRole.admin ||
      this == UserRole.editor ||
      this == UserRole.staff;

  bool get isViewer => this == UserRole.viewer;

  String get label {
    switch (this) {
      case UserRole.artist:
        return 'Artist / Talent';
      case UserRole.producer:
        return 'Producer / Casting Director';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.editor:
        return 'Content Editor';
      case UserRole.viewer:
        return 'Viewer (Read-only)';
      case UserRole.staff:
        return 'Staff';
    }
  }
}
