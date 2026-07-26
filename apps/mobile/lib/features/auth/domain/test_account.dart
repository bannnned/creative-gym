class TestAccount {
  const TestAccount({
    required this.userId,
    required this.label,
    required this.isAdmin,
    required this.isCurrent,
  });

  final String userId;
  final String label;
  final bool isAdmin;
  final bool isCurrent;
}
