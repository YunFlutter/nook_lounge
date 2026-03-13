import 'package:nook_lounge_app/domain/model/page_guide_step.dart';

class PageGuideContent {
  const PageGuideContent({
    required this.storageKey,
    required this.badgeLabel,
    required this.title,
    required this.description,
    required this.primaryActionLabel,
    required this.steps,
  });

  final String storageKey;
  final String badgeLabel;
  final String title;
  final String description;
  final String primaryActionLabel;
  final List<PageGuideStep> steps;
}
