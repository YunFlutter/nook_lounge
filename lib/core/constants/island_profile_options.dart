class IslandProfileOptions {
  const IslandProfileOptions._();

  static const String northHemisphere = '북반구';
  static const String southHemisphere = '남반구';

  static const List<String> hemispheres = <String>[
    northHemisphere,
    southHemisphere,
  ];

  static const Map<String, String> hemisphereAssetByName = <String, String>{
    northHemisphere: 'assets/images/icon_northern_hemisphere_compass.png',
    southHemisphere: 'assets/images/icon_southern_hemisphere_compass.png',
  };

  static const List<String> fruits = <String>['사과', '체리', '오렌지', '복숭아', '배'];

  static const Map<String, String> fruitEmojiByName = <String, String>{
    '사과': '🍎',
    '체리': '🍒',
    '오렌지': '🍊',
    '복숭아': '🍑',
    '배': '🍐',
  };

  static const String fallbackFruitEmoji = '🍀';
}
