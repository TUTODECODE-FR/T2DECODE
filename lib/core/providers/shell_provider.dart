import 'package:flutter/material.dart';

class ShellProvider extends ChangeNotifier {
  String _title = 'T2CODE';
  List<Widget>? _actions;
  bool _showBackButton = false;
  VoidCallback? _onBack;
  String _activeRoute = '/';

  String get title => _title;
  List<Widget>? get actions => _actions;
  bool get showBackButton => _showBackButton;
  VoidCallback? get onBack => _onBack;
  String get activeRoute => _activeRoute;

  void updateShell({
    String? title,
    List<Widget>? actions,
    bool? showBackButton,
    VoidCallback? onBack,
    String? activeRoute,
  }) {
    if (title != null) _title = title;
    if (actions != null) _actions = actions;
    if (showBackButton != null) _showBackButton = showBackButton;
    _onBack = onBack; // Can be null
    if (activeRoute != null) _activeRoute = activeRoute;
    
    notifyListeners();
  }

  void setActiveRoute(String route) {
    if (_activeRoute != route) {
      _activeRoute = route;
      notifyListeners();
    }
  }
}
