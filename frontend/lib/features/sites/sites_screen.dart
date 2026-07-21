import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';
import '../../shared/workspace_scope.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = '';
  String _sortBy = 'name';
  String _sortOrder = 'desc';
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _sites = <Map<String, dynamic>>[];
  bool _searchExpanded = false;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  DateTime? _parseDisplayDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) {
      return null;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }
    return DateTime.tryParse('$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
  }

  String? _toApiDate(String displayDate) {
    final parsed = _parseDisplayDate(displayDate.trim());
    if (parsed == null) {
      return null;
    }
    return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _fromApiDate(String? apiDate) {
    if (apiDate == null || apiDate.isEmpty) {
      return '';
    }
    final parsed = DateTime.tryParse(apiDate);
    if (parsed == null) {
      return '';
    }
    return _formatDate(parsed);
  }

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiRegistry.sites.listSites(
        status: _statusFilter,
        search: _searchController.text.trim(),
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _sites = items;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'planned':
        return 'Planned';
      case 'active':
        return 'Active';
      case 'on_hold':
        return 'On Hold';
      case 'closed':
        return 'Closed';
      default:
        return 'All';
    }
  }

  void _enterWorkspace(Map<String, dynamic> site) {
    final workspace = WorkspaceScope.of(context);
    workspace.selectSite(site['id'] as int);
    Navigator.of(context).pushReplacementNamed('/workspace');
  }

  Future<void> _showSiteDialog({Map<String, dynamic>? existing}) async {
    final rootContext = context;
    final nameController = TextEditingController(text: existing?['name']?.toString() ?? '');
    final locationController =
        TextEditingController(text: existing?['site_location']?.toString() ?? '');
    final ownerController = TextEditingController(text: existing?['owner_name']?.toString() ?? '');
    final startController =
      TextEditingController(text: _fromApiDate(existing?['planned_start_date']?.toString()));
    final endController =
      TextEditingController(text: _fromApiDate(existing?['planned_end_date']?.toString()));
    String status = existing?['status']?.toString() ?? 'planned';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Site' : 'Edit Site'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Site Location'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ownerController,
                    decoration: const InputDecoration(labelText: 'Owner Name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: startController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Planned Start (DD/MM/YYYY) *',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final initial = _parseDisplayDate(startController.text) ?? DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        startController.text = _formatDate(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: endController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Planned End (DD/MM/YYYY)',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final initial = _parseDisplayDate(endController.text) ?? DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        endController.text = _formatDate(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'planned', child: Text('Planned')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'on_hold', child: Text('On Hold')),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (value) {
                      status = value ?? 'planned';
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final siteLocation = locationController.text.trim();
                final ownerName = ownerController.text.trim();
                final plannedStartDate = _toApiDate(startController.text.trim());
                final plannedEndDate = _toApiDate(endController.text.trim());

                if (name.isEmpty || siteLocation.isEmpty || ownerName.isEmpty || plannedStartDate == null) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Name, Site Location, Owner Name, and Planned Start Date are mandatory.',
                      ),
                    ),
                  );
                  return;
                }

                    final workspace = WorkspaceScope.of(context);
                if (endController.text.trim().isNotEmpty && plannedEndDate == null) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('Planned End Date must be in DD/MM/YYYY format.')),
                  );
                  return;
                }
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sites', style: theme.textTheme.headlineMedium),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pick a site once, then enter its workspace to manage inventory, workloads, and budgets in one place.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _searchExpanded = !_searchExpanded),
                              icon: Icon(_searchExpanded ? Icons.search_off_rounded : Icons.search_rounded),
                              tooltip: _searchExpanded ? 'Hide search' : 'Search sites',
                            ),
                final payload = <String, dynamic>{
                  'name': name,
                  'site_location': siteLocation,
                  'owner_name': ownerName,
                  'planned_start_date': plannedStartDate,
                  'status': status,
                  if (plannedEndDate != null) 'planned_end_date': plannedEndDate,
                        const SizedBox(height: 14),
                        if (_searchExpanded)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) => _loadSites(),
                              decoration: InputDecoration(
                                labelText: 'Search by site, owner, or location',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadSites();
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ),
                          ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: '', label: Text('All')),
                                ButtonSegment(value: 'active', label: Text('Active')),
                                ButtonSegment(value: 'planned', label: Text('Planned')),
                                ButtonSegment(value: 'on_hold', label: Text('On Hold')),
                                ButtonSegment(value: 'closed', label: Text('Closed')),
                              ],
                              selected: <String>{_statusFilter},
                              onSelectionChanged: (selection) {
                                setState(() => _statusFilter = selection.first);
                                _loadSites();
                              },
                            ),
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<String>(
                                value: _sortBy,
                                items: const [
                                  DropdownMenuItem(value: 'name', child: Text('Sort: Name')),
                                  DropdownMenuItem(value: 'created_at', child: Text('Sort: Created')),
                                  DropdownMenuItem(value: 'planned_start_date', child: Text('Sort: Start Date')),
                                  DropdownMenuItem(value: 'planned_end_date', child: Text('Sort: End Date')),
                                ],
                                onChanged: (value) {
                                  setState(() => _sortBy = value ?? 'name');
                                  _loadSites();
                                },
                                decoration: const InputDecoration(labelText: 'Sort'),
                              ),
                            ),
                            Tooltip(
                              message: _sortOrder == 'asc' ? 'Ascending' : 'Descending',
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc');
                                  _loadSites();
                                },
                                icon: Icon(_sortOrder == 'asc' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                                label: Text(_sortOrder == 'asc' ? 'A to Z' : 'Z to A'),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _statusFilter = '';
                                  _sortBy = 'name';
                                  _sortOrder = 'desc';
                                  _searchController.clear();
                                });
                                _loadSites();
                              },
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('Reset'),
                            ),
                          ],
                        ),
                } else {
                  await ApiRegistry.sites.updateSite(existing['id'] as int, payload);
                }
                if (!mounted) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await _loadSites();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Sites', style: theme.textTheme.headlineMedium)),
            FilledButton.icon(
              onPressed: () => _showSiteDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Site'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('List, filter, sort, add, and modify sites from PostgreSQL.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(labelText: 'Search', prefixIcon: Icon(Icons.search)),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: '', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'planned', child: Text('Planned')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'on_hold', child: Text('On Hold')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (value) => setState(() => _statusFilter = value ?? ''),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'created_at', child: Text('Sort: Created')),
                  DropdownMenuItem(value: 'name', child: Text('Sort: Name')),
                  DropdownMenuItem(value: 'planned_start_date', child: Text('Sort: Start Date')),
                  DropdownMenuItem(value: 'planned_end_date', child: Text('Sort: End Date')),
                ],
                onChanged: (value) => setState(() => _sortBy = value ?? 'created_at'),
                decoration: const InputDecoration(labelText: 'Sort By'),
              ),
            ),
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<String>(
                value: _sortOrder,
                items: const [
                  DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                  DropdownMenuItem(value: 'desc', child: Text('Descending')),
                ],
                onChanged: (value) => setState(() => _sortOrder = value ?? 'desc'),
                decoration: const InputDecoration(labelText: 'Order'),
              ),
            ),
            FilledButton.icon(onPressed: _loadSites, icon: const Icon(Icons.filter_alt), label: const Text('Apply')),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _sites.isEmpty
                        ? const Center(child: Text('No sites found'))
                        : ListView.separated(
                            itemCount: _sites.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final site = _sites[index];
                              return ListTile(
                                title: Text(site['name']?.toString() ?? '-'),
                                subtitle: Text(
                                  '${site['site_location'] ?? '-'} • Owner: ${site['owner_name'] ?? '-'}',
                                ),
                                onTap: () {
                                  workspace.selectSite(site['id'] as int);
                                },
                                trailing: Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Chip(label: Text(_statusLabel(site['status']?.toString() ?? ''))),
                                    OutlinedButton.icon(
                                      onPressed: () => _enterWorkspace(site),
                                      icon: const Icon(Icons.launch_rounded),
                                      label: const Text('Enter Workspace'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _showSiteDialog(existing: site),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}
