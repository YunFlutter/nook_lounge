class SettingsFaqItem {
  const SettingsFaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    this.status = 'active',
  });

  final String id;
  final String category;
  final String question;
  final String answer;
  final String status;
}
