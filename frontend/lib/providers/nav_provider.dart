import 'package:flutter/material.dart';

/// Simple provider to control the MainScaffold's current tab index.
/// Lets any screen switch tabs (e.g., Home → Profile on avatar tap).
class NavProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void setIndex(int i) {
    if (_index == i) return;
    _index = i;
    notifyListeners();
  }
}
