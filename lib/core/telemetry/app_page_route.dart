import 'package:flutter/material.dart';

class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({
    required String screenName,
    required super.builder,
    super.fullscreenDialog,
    super.maintainState,
  }) : super(settings: RouteSettings(name: screenName));
}
