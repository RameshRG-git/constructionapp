import 'package:flutter/material.dart';

import 'api_registry.dart';

class AuthController extends ChangeNotifier {
  AuthController._();

  static final AuthController instance = AuthController._();

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _tenants = <Map<String, dynamic>>[];
  List<String> _accessRoles = <String>[];
  bool _isTenantAdmin = false;
  bool _isRestoring = true;

  Map<String, dynamic>? get user => _user;
  List<Map<String, dynamic>> get tenants => _tenants;
  List<String> get accessRoles => _accessRoles;
  bool get isTenantAdmin => _isTenantAdmin;
  bool get isRestoring => _isRestoring;
  bool get isAuthenticated => _user != null;

  String get displayName =>
      _user?['full_name']?.toString() ?? _user?['username']?.toString() ?? 'Signed in';

  String? get activeTenantSlug => ApiRegistry.client.tenantName;

  void _applySession(Map<String, dynamic> payload) {
    _user = payload['user'] as Map<String, dynamic>?;
    _tenants = (payload['tenants'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    _accessRoles = (payload['access_roles'] as List<dynamic>? ?? <dynamic>[])
        .map((role) => role.toString())
        .toList();
    _isTenantAdmin = payload['is_tenant_admin'] == true;

    final defaultTenant = payload['default_tenant']?.toString();
    if (defaultTenant != null && defaultTenant.isNotEmpty) {
      ApiRegistry.client.setTenantName(defaultTenant);
    }
  }

  Future<void> restoreSession() async {
    try {
      final payload = await ApiRegistry.auth.session();
      _applySession(payload);
    } catch (_) {
      _clearState();
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String identifier, String password) async {
    final payload = await ApiRegistry.auth.login(identifier, password);
    _applySession(payload);
    _isRestoring = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await ApiRegistry.auth.logout();
    } finally {
      _clearState();
      notifyListeners();
    }
  }

  void switchTenant(String slug) {
    ApiRegistry.client.setTenantName(slug);
    notifyListeners();
  }

  void _clearState() {
    _user = null;
    _tenants = <Map<String, dynamic>>[];
    _accessRoles = <String>[];
    _isTenantAdmin = false;
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({super.key, required AuthController controller, required super.child})
      : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope is missing from the widget tree');
    return scope!.notifier!;
  }
}
