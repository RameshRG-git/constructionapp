import 'dart:async';

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
  Timer? _refreshDebounce;
  String _statusFilter = 'all';
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _sites = <Map<String, dynamic>>[];

  List<Map<String, dynamic>> get _visibleSites {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _sites.where((site) {
      final status = site['status']?.toString().toLowerCase() ?? '';
      final haystack = [
        site['name'],
        site['site_location'],
        site['owner_name'],
      ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');

      final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
      final matchesQuery = query.isEmpty || haystack.contains(query);
      return matchesStatus && matchesQuery;
    }).toList();

    int compareDate(String? left, String? right) {
      final leftDate = DateTime.tryParse(left ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate = DateTime.tryParse(right ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return leftDate.compareTo(rightDate);
    }

    filtered.sort((left, right) {
      int result;
      switch (_sortBy) {
        case 'name':
          result = (left['name']?.toString() ?? '').compareTo(right['name']?.toString() ?? '');
          break;
        case 'planned_start_date':
          result = compareDate(left['planned_start_date']?.toString(), right['planned_start_date']?.toString());
          break;
        case 'planned_end_date':
          result = compareDate(left['planned_end_date']?.toString(), right['planned_end_date']?.toString());
          break;
        default:
          result = compareDate(left['created_at']?.toString(), right['created_at']?.toString());
      }
      return _sortOrder == 'asc' ? result : -result;
    });

    return filtered;
  }

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

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiRegistry.sites.listSites(sortBy: 'created_at', sortOrder: 'desc');
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

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _openWorkspace(Map<String, dynamic> site) {
    WorkspaceScope.of(context).selectSite(site);
    Navigator.of(context).pushNamed('/site-workspace');
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

                if (endController.text.trim().isNotEmpty && plannedEndDate == null) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('Planned End Date must be in DD/MM/YYYY format.')),
                  );
                  return;
                }

                final payload = <String, dynamic>{
                  'name': name,
                  'site_location': siteLocation,
                  'owner_name': ownerName,
                  'planned_start_date': plannedStartDate,
                  'status': status,
                  if (plannedEndDate != null) 'planned_end_date': plannedEndDate,
                };
                if (existing == null) {
                  await ApiRegistry.sites.createSite(payload);
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
    final visibleSites = _visibleSites;

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
        Text('Pick a site once, then enter its workspace to manage everything in one place.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _scheduleRefresh(),
                  decoration: const InputDecoration(
                    labelText: 'Search sites, locations, or owners',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in const ['all', 'planned', 'active', 'on_hold', 'closed'])
                      ChoiceChip(
                        label: Text(
                          status == 'all'
                              ? 'All'
                              : status == 'on_hold'
                                  ? 'On Hold'
                                  : status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '),
                        ),
                        selected: _statusFilter == status,
                        onSelected: (_) => setState(() => _statusFilter = status),
                      ),
                    const SizedBox(width: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'created_at', label: Text('Newest')),
                        ButtonSegment(value: 'name', label: Text('Name')),
                        ButtonSegment(value: 'planned_start_date', label: Text('Start')),
                        ButtonSegment(value: 'planned_end_date', label: Text('End')),
                      ],
                      selected: {_sortBy},
                      onSelectionChanged: (value) => setState(() => _sortBy = value.first),
                    ),
                    IconButton(
                      tooltip: _sortOrder == 'asc' ? 'Ascending' : 'Descending',
                      onPressed: () => setState(() => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc'),
                      icon: Icon(
                        _sortOrder == 'asc' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _loadSites,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : visibleSites.isEmpty
                      ? const Center(child: Text('No sites found'))
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 360,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: visibleSites.length,
                          itemBuilder: (context, index) {
                            final site = visibleSites[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _openWorkspace(site),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              site['name']?.toString() ?? '-',
                                              style: theme.textTheme.titleLarge,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Chip(label: Text(site['status']?.toString() ?? '-')),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(site['site_location']?.toString() ?? '-', style: theme.textTheme.bodyLarge),
                                      const SizedBox(height: 6),
                                      Text('Owner: ${site['owner_name']?.toString() ?? '-'}'),
                                      const Spacer(),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => _showSiteDialog(existing: site),
                                            icon: const Icon(Icons.edit_outlined),
                                            label: const Text('Edit'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
          ),
      ],
    );
  }
}
