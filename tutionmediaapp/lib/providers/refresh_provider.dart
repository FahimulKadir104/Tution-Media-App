import 'package:flutter/material.dart';

class RefreshProvider with ChangeNotifier {
  void notifyRefresh() => notifyListeners();
}
