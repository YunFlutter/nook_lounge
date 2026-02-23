import 'package:flutter_riverpod/flutter_riverpod.dart';

class PushOfferIntentNotifier extends StateNotifier<String?> {
  PushOfferIntentNotifier() : super(null);

  void setOfferId(String offerId) {
    final normalized = offerId.trim();
    if (normalized.isEmpty) {
      return;
    }
    state = normalized;
  }

  void clear() {
    state = null;
  }
}
