import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';
import '../../shared/workspace_scope.dart';

class WorkloadsScreen extends StatefulWidget {
  const WorkloadsScreen({super.key});

  @override
  State<WorkloadsScreen> createState() => _WorkloadsScreenState();
}

class _WorkloadsScreenState extends State<WorkloadsScreen> {
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  int? _siteId;
  String _status = '';
  String _assignee = '';
  String _sortBy = 'due_date';
  String _sortOrder = 'asc';
  bool _isLoading = false;
  String? _error;

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
    final workspaceSiteId = WorkspaceScope.of(context).selectedSiteId;
    setState(() {
      _siteId = workspaceSiteId;
    });
    await _loadWorkloads();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final workspaceSiteId = WorkspaceScope.of(context).selectedSiteId;
    if (workspaceSiteId != null && workspaceSiteId != _siteId) {
      _siteId = workspaceSiteId;
      _loadWorkloads();
    }
  }

  Future<void> _loadWorkloads() async {
    if (_siteId == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiRegistry.workloads.listWorkloads(
        _siteId!,
        status: _status,
        assignee: _assignee,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _items = items;
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

  Future<void> _showAssignmentDialog({Map<String, dynamic>? existing}) async {
    if (_siteId == null) {
      return;
    }
    final rootContext = context;

    final assigneeTypeController =
        TextEditingController(text: existing?['assignee_type']?.toString() ?? 'team');
    final assigneeNameController =
        TextEditingController(text: existing?['assignee_name']?.toString() ?? '');
    final titleController = TextEditingController(text: existing?['title']?.toString() ?? '');
    final descriptionController =
        TextEditingController(text: existing?['description']?.toString() ?? '');
    final priorityController = TextEditingController(text: existing?['priority']?.toString() ?? 'normal');
    final dueDateController = TextEditingController(text: _fromApiDate(existing?['due_date']?.toString()));
    final estimatedHoursController =
        TextEditingController(text: existing?['estimated_hours']?.toString() ?? '0');
    String status = existing?['status']?.toString() ?? 'open';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Workload' : 'Edit Workload'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: assigneeTypeController,
                    decoration: const InputDecoration(labelText: 'Assignee Type'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: assigneeNameController,
                    decoration: const InputDecoration(labelText: 'Assignee Name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priorityController,
                    decoration: const InputDecoration(labelText: 'Priority'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Open')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    ],
                    onChanged: (value) => status = value ?? 'open',
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dueDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Due Date (DD/MM/YYYY) *',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final initial = _parseDisplayDate(dueDateController.text) ?? DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        dueDateController.text = _formatDate(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: estimatedHoursController,
                    decoration: const InputDecoration(labelText: 'Estimated Hours'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final dueDate = _toApiDate(dueDateController.text.trim());
                if (dueDate == null) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('Due Date is mandatory and must be in DD/MM/YYYY format.')),
                  );
                  return;
                }

                final payload = <String, dynamic>{
                  'assignee_type': assigneeTypeController.text.trim(),
                  'assignee_name': assigneeNameController.text.trim(),
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'priority': priorityController.text.trim(),
                  'status': status,
                  'due_date': dueDate,
                  'estimated_hours': double.tryParse(estimatedHoursController.text.trim()) ?? 0,
                };
                if (existing == null) {
                  await ApiRegistry.workloads.createWorkload(_siteId!, payload);
                } else {
                  await ApiRegistry.workloads.updateWorkload(existing['id'] as int, payload);
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
      await _loadWorkloads();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspace = WorkspaceScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Workloads', style: theme.textTheme.headlineMedium)),
            FilledButton.icon(
              onPressed: _siteId == null ? null : () => _showAssignmentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Workload'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Workloads stay inside the selected site workspace.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        if (workspace.selectedSite != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Working in ${workspace.selectedSiteName}')),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/site-workspace'),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open workspace'),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in const [
                  ('', 'All'),
                  ('open', 'Open'),
                  ('in_progress', 'In Progress'),
                  ('blocked', 'Blocked'),
                  ('completed', 'Completed'),
                ])
                  ChoiceChip(
                    label: Text(status.$2),
                    selected: _status == status.$1,
                    onSelected: (_) {
                      setState(() => _status = status.$1);
                      _loadWorkloads();
                    },
                  ),
              ],
            ),
            SizedBox(
              width: 220,
              child: TextField(
                decoration: const InputDecoration(labelText: 'Search assignee'),
                onChanged: (value) {
                  setState(() => _assignee = value);
                  _loadWorkloads();
                },
              ),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'due_date', label: Text('Due date')),
                ButtonSegment(value: 'priority', label: Text('Priority')),
                ButtonSegment(value: 'assignee_name', label: Text('Assignee')),
                ButtonSegment(value: 'status', label: Text('Status')),
              ],
              selected: {_sortBy},
              onSelectionChanged: (selection) {
                setState(() => _sortBy = selection.first);
                _loadWorkloads();
              },
            ),
            IconButton(
              onPressed: () {
                setState(() => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc');
                _loadWorkloads();
              },
              icon: Icon(
                _sortOrder == 'asc' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              ),
            ),
            OutlinedButton.icon(onPressed: _loadWorkloads, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh')),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _items.isEmpty
                        ? const Center(child: Text('No assignments found'))
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return ListTile(
                                leading: const Icon(Icons.groups_2_outlined),
                                title: Text(item['title']?.toString() ?? '-'),
                                subtitle: Text(
                                  '${item['assignee_name'] ?? '-'} • Due: ${item['due_date'] ?? '-'} • ${item['priority'] ?? '-'}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(label: Text(item['status']?.toString() ?? '-')),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _showAssignmentDialog(existing: item),
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
