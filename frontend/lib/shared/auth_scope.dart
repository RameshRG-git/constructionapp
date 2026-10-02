import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'api_registry.dart';

class AuthController extends ChangeNotifier {
  AuthController._() {
    ApiRegistry.client.onUnauthorized = _handleUnauthorized;
    ApiRegistry.client.onServerActivity = () => _lastServerContact = DateTime.now();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  static final AuthController instance = AuthController._();

  // Shared via localStorage so activity in any open tab keeps every tab signed in.
  static const String _activityStorageKey = 'constructionapp.lastActivity';
  static const Duration _warningLead = Duration(seconds: 60);
  static const Duration _activityWriteThrottle = Duration(seconds: 5);
  static const String _idleSignOutMessage = 'You were signed out after a period of inactivity. Please sign in again.';

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _tenants = <Map<String, dynamic>>[];
  List<String> _accessRoles = <String>[];
  bool _isTenantAdmin = false;
  bool _isRestoring = true;

  Duration _idleTimeout = const Duration(minutes: 15);
  DateTime _lastActivity = DateTime.now();
  DateTime _lastActivityWrite = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastServerContact = DateTime.now();
  Timer? _idleTimer;
  bool _keepAliveInFlight = false;
  int? _idleWarningSecondsLeft;
  String? _signOutReason;

  Map<String, dynamic>? get user => _user;
  List<Map<String, dynamic>> get tenants => _tenants;
  List<String> get accessRoles => _accessRoles;
  bool get isTenantAdmin => _isTenantAdmin;
  bool get isRestoring => _isRestoring;
  bool get isAuthenticated => _user != null;

  /// Seconds until automatic sign-out, or null when no warning should be shown.
  int? get idleWarningSecondsLeft => _idleWarningSecondsLeft;

  /// Why the user was signed out without asking (shown on the login screen).
  String? get signOutReason => _signOutReason;

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

    final sessionInfo = payload['session'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final idleSeconds = (sessionInfo['idle_timeout_seconds'] as num?)?.toInt();
    if (idleSeconds != null && idleSeconds > 0) {
      _idleTimeout = Duration(seconds: idleSeconds);
    }
    _signOutReason = null;
    _lastServerContact = DateTime.now();
    _writeActivity(DateTime.now());
    _startIdleTimer();
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

  void clearSignOutReason() {
    if (_signOutReason != null) {
      _signOutReason = null;
      notifyListeners();
    }
  }

  /// Records user interaction (click, scroll, keypress) to reset the idle countdown.
  void recordUserActivity() {
    if (!isAuthenticated) {
      return;
    }
    final now = DateTime.now();
    _lastActivity = now;
    if (now.difference(_lastActivityWrite) >= _activityWriteThrottle) {
      _writeActivity(now);
    }
  }

  /// Dismisses the idle warning and extends the server session.
  void staySignedIn() {
    _writeActivity(DateTime.now());
    _idleWarningSecondsLeft = null;
    notifyListeners();
    _keepAlive();
  }

  bool _onKeyEvent(KeyEvent event) {
    recordUserActivity();
    return false;
  }

  void _writeActivity(DateTime when) {
    _lastActivity = when;
    _lastActivityWrite = when;
    try {
      web.window.localStorage.setItem(_activityStorageKey, when.millisecondsSinceEpoch.toString());
    } catch (_) {
      // Storage can be unavailable (e.g. privacy mode); the in-memory value still works.
    }
  }

  DateTime _sharedLastActivity() {
    var latest = _lastActivity;
    try {
      final stored = int.tryParse(web.window.localStorage.getItem(_activityStorageKey) ?? '');
      if (stored != null) {
        final fromOtherTabs = DateTime.fromMillisecondsSinceEpoch(stored);
        if (fromOtherTabs.isAfter(latest)) {
          latest = fromOtherTabs;
        }
      }
    } catch (_) {
      // Fall back to this tab's activity only.
    }
    return latest;
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkIdle());
  }

  void _checkIdle() {
    if (!isAuthenticated) {
      return;
    }
    final now = DateTime.now();
    final lastActivity = _sharedLastActivity();
    final remaining = _idleTimeout - now.difference(lastActivity);
    if (remaining <= Duration.zero) {
      _expireForInactivity();
      return;
    }

    final warning = remaining <= _warningLead ? remaining.inSeconds : null;
    if (warning != _idleWarningSecondsLeft) {
      _idleWarningSecondsLeft = warning;
      notifyListeners();
    }

    // The server only sees API calls, so ping it while the user is active but not calling the API.
    final keepAliveEvery = Duration(
      milliseconds: math.min(const Duration(minutes: 2).inMilliseconds, _idleTimeout.inMilliseconds ~/ 3),
    );
    if (lastActivity.isAfter(_lastServerContact) && now.difference(_lastServerContact) >= keepAliveEvery) {
      _keepAlive();
    }
  }

  Future<void> _keepAlive() async {
    if (_keepAliveInFlight || !isAuthenticated) {
      return;
    }
    _keepAliveInFlight = true;
    try {
      await ApiRegistry.auth.session();
    } catch (_) {
      // A 401 is handled by _handleUnauthorized; other failures retry on the next tick.
    } finally {
      _keepAliveInFlight = false;
    }
  }

  void _expireForInactivity() {
    // Best effort: revoke server-side too so the cookie can't be reused.
    ApiRegistry.auth.logout().catchError((_) => <String, dynamic>{});
    _endSession(_idleSignOutMessage);
  }

  void _handleUnauthorized(String errorCode) {
    if (!isAuthenticated) {
      return;
    }
    _endSession(
      errorCode == 'session_expired' ? _idleSignOutMessage : 'Your session has ended. Please sign in again.',
    );
  }

  void _endSession(String reason) {
    _clearState();
    _signOutReason = reason;
    notifyListeners();
  }

  void _clearState() {
    _idleTimer?.cancel();
    _idleTimer = null;
    _idleWarningSecondsLeft = null;
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
