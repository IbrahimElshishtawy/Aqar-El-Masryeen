enum AppRole {
  owner('owner', 'role_owner'),
  accountant('accountant', 'role_accountant'),
  employee('employee', 'role_employee'),
  viewer('viewer', 'role_viewer');

  const AppRole(this.key, this.labelKey);

  final String key;
  final String labelKey;

  static AppRole fromKey(String? value) {
    return AppRole.values.firstWhere(
      (role) => role.key == value,
      orElse: () => AppRole.viewer,
    );
  }
}
