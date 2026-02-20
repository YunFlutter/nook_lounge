import 'package:freezed_annotation/freezed_annotation.dart';

part 'island_profile.freezed.dart';

@freezed
sealed class IslandProfile with _$IslandProfile {
  const IslandProfile._();

  const factory IslandProfile({
    required String id,
    required String islandName,
    required String representativeName,
    required String hemisphere,
    required String nativeFruit,
    String? imageUrl,
  }) = _IslandProfile;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'islandName': islandName,
      'representativeName': representativeName,
      'hemisphere': hemisphere,
      'nativeFruit': nativeFruit,
      'imageUrl': imageUrl,
    };
  }
}
