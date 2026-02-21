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

  factory IslandProfile.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return IslandProfile(
      id: (map['id'] as String?)?.trim().isNotEmpty == true
          ? (map['id'] as String).trim()
          : id,
      islandName: (map['islandName'] as String?)?.trim() ?? '이름 없는 섬',
      representativeName:
          (map['representativeName'] as String?)?.trim() ?? '대표 주민',
      hemisphere: (map['hemisphere'] as String?)?.trim() ?? '북반구',
      nativeFruit: (map['nativeFruit'] as String?)?.trim() ?? '복숭아',
      imageUrl: (map['imageUrl'] as String?)?.trim(),
    );
  }

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
