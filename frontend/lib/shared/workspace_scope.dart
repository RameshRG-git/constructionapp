import 'package:flutter/material.dart';

class WorkspaceController extends ChangeNotifier {
  WorkspaceController._();

  static final WorkspaceController instance = WorkspaceController._();

  Map<String, dynamic>? _selectedSite;

  Map<String, dynamic>? get selectedSite => _selectedSite;

  int? get selectedSiteId => _selectedSite?['id'] as int?;

  String get selectedSiteName => _selectedSite?['name']?.toString() ?? 'Select a site';

  void selectSite(Map<String, dynamic> site) {
    _selectedSite = Map<String, dynamic>.from(site);
    notifyListeners();
  }

  void clearSite() {
    if (_selectedSite == null) {
      return;
    }
    _selectedSite = null;
    notifyListeners();
  }
}

class WorkspaceScope extends InheritedNotifier<WorkspaceController> {
  const WorkspaceScope({super.key, required WorkspaceController controller, required super.child})
      : super(notifier: controller);

  static WorkspaceController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WorkspaceScope>();
    assert(scope != null, 'WorkspaceScope is missing from the widget tree');
    return scope!.notifier!;
  }
}