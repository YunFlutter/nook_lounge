import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_island_draft.freezed.dart';

@freezed
sealed class CreateIslandDraft with _$CreateIslandDraft {
  const CreateIslandDraft._();

  const factory CreateIslandDraft({
    required String islandName,
    required String representativeName,
    required String hemisphere,
    required String nativeFruit,
    String? imageUrl,
  }) = _CreateIslandDraft;
}
