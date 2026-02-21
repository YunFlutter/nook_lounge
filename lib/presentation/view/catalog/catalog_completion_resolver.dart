import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';

bool isDonationCategory(String category) {
  return const <String>{'곤충', '물고기', '해산물', '화석', '미술품'}.contains(category);
}

bool resolveCatalogCompleted({
  required CatalogItem item,
  required Map<String, CatalogUserState> userStates,
}) {
  final userState = userStates[item.id];
  if (userState == null) {
    return false;
  }

  if (isDonationCategory(item.category)) {
    return userState.donated;
  }
  return userState.owned;
}

int resolveCatalogCompletedCount({
  required String category,
  required List<CatalogItem> items,
  required Map<String, CatalogUserState> userStates,
}) {
  if (items.isEmpty) {
    return 0;
  }
  return items
      .where(
        (item) => resolveCatalogCompleted(item: item, userStates: userStates),
      )
      .length;
}
