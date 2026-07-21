import 'package:flutter/foundation.dart';

import '../features/sites/site_api.dart';

class WorkspaceState extends ChangeNotifier {
  WorkspaceState({required SiteApi sitesApi}) : _sitesApi = sitesApi;

  final SiteApi _sitesApi;

  List<Map<String, dynamic>> _sites = <Map<String, dynamic>>[];
  int? _selectedSiteId;
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;

  List<Map<String, dynamic>> get sites => _sites;
  int? get selectedSiteId => _selectedSiteId;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  String? get error => _error;

  Map<String, dynamic>? get selectedSite {
    if (_selectedSiteId == null) {
      return null;
    }
    for (final site in _sites) {
      if (site['id'] == _selectedSiteId) {
        return site;
      }
    }
    return null;
  }

  Future<void> ensureLoaded() async {
    if (_initialized || _isLoading) {
      return;
    }
    await reloadSites();
  }

  Future<void> reloadSites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _sitesApi.listSites(sortBy: 'name', sortOrder: 'asc');
      final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();

      _sites = items;
      if (_selectedSiteId == null || !_sites.any((site) => site['id'] == _selectedSiteId)) {
        _selectedSiteId = _sites.isEmpty ? null : _sites.first['id'] as int;
      }
      _initialized = true;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectSite(int? siteId) {
    if (siteId == _selectedSiteId) {
      return;
    }
    _selectedSiteId = siteId;
    notifyListeners();
  }
}
