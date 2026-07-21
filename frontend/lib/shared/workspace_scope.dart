import 'package:flutter/widgets.dart';

import 'workspace_state.dart';

class WorkspaceScope extends InheritedNotifier<WorkspaceState> {
  const WorkspaceScope({
    super.key,
    required WorkspaceState notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static WorkspaceState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WorkspaceScope>();
    assert(scope != null, 'WorkspaceScope is missing in widget tree.');
    return scope!.notifier!;
  }
}
