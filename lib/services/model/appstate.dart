import 'package:flutter/cupertino.dart';

class AppStateModel extends ChangeNotifier {
  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  void changeActiveTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }
}
