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
  List<Map<String, dynamic>> _teamMembers = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _roles = <Map<String, dynamic>>[];
  int? _siteId;
  String _status = '';
  String _search = '';
  String _onDateFilter = '';
  String _fromDateFilter = '';
  String _toDateFilter = '';
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

  String _toIsoDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _displayDateFromIso(String value) {
    if (value.isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return '-';
    }
    return _formatDate(parsed);
  }

  double _roleDayRate(Map<String, dynamic>? role) {
    if (role == null) {
      return 0;
    }
    final value = role['daily_pay_rate'];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic>? _roleById(int? roleId) {
    if (roleId == null) {
      return null;
    }
    for (final role in _roles) {
      if (role['id'] == roleId) {
        return role;
      }
    }
    return null;
  }

  int? _roleIdByTitle(String? title) {
    if (title == null || title.isEmpty) {
      return null;
    }
    for (final role in _roles) {
      if ((role['title']?.toString() ?? '') == title) {
        return role['id'] as int;
      }
    }
    return null;
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
    await _loadTeamMembers();
    await _loadRoles();
    await _loadWorkloads();
  }

  Future<void> _loadTeamMembers() async {
    final response = await ApiRegistry.team.listMembers(includeInactive: false, sortBy: 'full_name', sortOrder: 'asc');
    final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (!mounted) {
      return;
    }
    setState(() {
      _teamMembers = items;
    });
  }

  Future<void> _loadRoles() async {
    final response = await ApiRegistry.team.listRoles(includeInactive: false);
    final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (!mounted) {
      return;
    }
    setState(() {
      _roles = items;
    });
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
        query: _search,
        onDate: _onDateFilter,
        fromDate: _fromDateFilter,
        toDate: _toDateFilter,
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

    final assigneeNameController =
        TextEditingController(text: existing?['assignee_name']?.toString() ?? '');
    final workloadTitleController = TextEditingController(text: existing?['title']?.toString() ?? '');

    final existingStart = existing?['week_start_date']?.toString() ?? existing?['due_date']?.toString();
    final existingEnd = existing?['week_end_date']?.toString() ?? existing?['due_date']?.toString();
    DateTime periodStartDate = existingStart == null || existingStart.isEmpty ? DateTime.now() : DateTime.parse(existingStart);
    DateTime periodEndDate = existingEnd == null || existingEnd.isEmpty ? periodStartDate : DateTime.parse(existingEnd);
    String mode = periodStartDate == periodEndDate ? 'day' : 'days';

    final periodStartController = TextEditingController(text: _formatDate(periodStartDate));
    final periodEndController = TextEditingController(text: _formatDate(periodEndDate));
    int? selectedMemberId;
    int? selectedRoleId = _roleIdByTitle(existing?['assignee_type']?.toString());
    for (final member in _teamMembers) {
      if ((member['full_name']?.toString() ?? '') == assigneeNameController.text.trim()) {
        selectedMemberId = member['id'] as int;
        selectedRoleId ??= _roleIdByTitle(member['job_title']?.toString());
        break;
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Map<String, dynamic>? selectedMember;
            for (final member in _teamMembers) {
              if (member['id'] == selectedMemberId) {
                selectedMember = member;
                break;
              }
            }
            final selectedRole = _roleById(selectedRoleId);
            final dayRate = _roleDayRate(selectedRole);
            final dayCount = periodEndDate.difference(periodStartDate).inDays + 1;
            final projectedCost = dayRate <= 0 ? null : (dayRate * dayCount);

            return AlertDialog(
              title: Text(existing == null ? 'Add Workload' : 'Edit Workload'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int?>(
                        initialValue: selectedMemberId,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Select team member')),
                          ..._teamMembers.map(
                            (member) => DropdownMenuItem<int?>(
                              value: member['id'] as int,
                              child: Text(member['full_name']?.toString() ?? '-'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMemberId = value;
                            if (selectedMemberId != null) {
                              for (final member in _teamMembers) {
                                if (member['id'] == selectedMemberId) {
                                  assigneeNameController.text = member['full_name']?.toString() ?? '';
                                  selectedRoleId = _roleIdByTitle(member['job_title']?.toString());
                                  break;
                                }
                              }
                            }
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Assignee'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        key: ValueKey<int?>(selectedRoleId),
                        initialValue: selectedRoleId,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Select title')),
                          ..._roles.map(
                            (role) => DropdownMenuItem<int?>(
                              value: role['id'] as int,
                              child: Text(role['title']?.toString() ?? '-'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedRoleId = value;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 10),
                      if (selectedMember != null || selectedRole != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (selectedMember != null)
                                Chip(label: Text('Assignee: ${selectedMember['full_name'] ?? '-'}')),
                              Chip(label: Text('Role: ${selectedRole?['title'] ?? selectedMember?['job_title'] ?? '-'}')),
                              Chip(label: Text('Day Rate: ${dayRate.toStringAsFixed(2)}')),
                              if (projectedCost != null)
                                Chip(label: Text('Projected Labor: ${projectedCost.toStringAsFixed(0)}')),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextField(controller: workloadTitleController, decoration: const InputDecoration(labelText: 'Workload Title')),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'day', label: Text('Record for Day')),
                          ButtonSegment(value: 'days', label: Text('Record for Days')),
                        ],
                        selected: {mode},
                        onSelectionChanged: (selection) {
                          setDialogState(() {
                            mode = selection.first;
                            if (mode == 'day') {
                              periodEndDate = periodStartDate;
                              periodEndController.text = _formatDate(periodEndDate);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: periodStartController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Date *',
                          suffixIcon: Icon(Icons.date_range_rounded),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: periodStartDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              periodStartDate = DateTime(picked.year, picked.month, picked.day);
                              periodStartController.text = _formatDate(periodStartDate);
                              if (mode == 'day' || periodEndDate.isBefore(periodStartDate)) {
                                periodEndDate = periodStartDate;
                                periodEndController.text = _formatDate(periodEndDate);
                              }
                            });
                          }
                        },
                      ),
                      if (mode == 'days') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: periodEndController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'End Date *',
                            suffixIcon: Icon(Icons.date_range_rounded),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: periodEndDate,
                              firstDate: periodStartDate,
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                periodEndDate = DateTime(picked.year, picked.month, picked.day);
                                periodEndController.text = _formatDate(periodEndDate);
                              });
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (projectedCost != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Projected Payroll: ${projectedCost.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    if (assigneeNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text('Please choose an assignee.')),
                      );
                      return;
                    }

                    final normalizedStart = DateTime(periodStartDate.year, periodStartDate.month, periodStartDate.day);
                    final normalizedEnd = mode == 'day'
                        ? normalizedStart
                        : DateTime(periodEndDate.year, periodEndDate.month, periodEndDate.day);
                    if (normalizedEnd.isBefore(normalizedStart)) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text('End date cannot be before start date.')),
                      );
                      return;
                    }

                    final dayCount = normalizedEnd.difference(normalizedStart).inDays + 1;
                    final selectedRole = _roleById(selectedRoleId);
                    final roleTitle = selectedRole?['title']?.toString() ?? selectedMember?['job_title']?.toString() ?? 'team';
                    final paidAmount = _roleDayRate(selectedRole) * dayCount;
                    final today = DateTime.now();
                    final todayDate = DateTime(today.year, today.month, today.day);
                    final effectiveStatus = normalizedEnd.isBefore(todayDate)
                        ? 'completed'
                        : (existing?['status']?.toString() ?? 'open');

                    final payload = <String, dynamic>{
                      'assignee_type': roleTitle,
                      'assignee_name': assigneeNameController.text.trim(),
                      'title': workloadTitleController.text.trim(),
                      'status': effectiveStatus,
                      'period_start_date': _toIsoDate(normalizedStart),
                      'period_end_date': _toIsoDate(normalizedEnd),
                      'due_date': _toIsoDate(normalizedEnd),
                      'estimated_hours': 8,
                      'paid_amount': paidAmount,
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
      },
    );

    if (saved == true) {
      await _loadWorkloads();
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
            Expanded(child: Text('Workloads', style: theme.textTheme.headlineMedium)),
            FilledButton.icon(
              onPressed: _siteId == null ? null : () => _showAssignmentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Workload'),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              width: 260,
              child: TextField(
                decoration: const InputDecoration(labelText: 'Search title or name'),
                onChanged: (value) {
                  setState(() => _search = value);
                  _loadWorkloads();
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked == null) {
                  return;
                }
                final iso = _toIsoDate(DateTime(picked.year, picked.month, picked.day));
                setState(() {
                  _onDateFilter = iso;
                  _fromDateFilter = '';
                  _toDateFilter = '';
                });
                await _loadWorkloads();
              },
              icon: const Icon(Icons.event_rounded),
              label: const Text('On Date'),
            ),
            OutlinedButton(
              onPressed: () async {
                final from = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (from == null) {
                  return;
                }
                final to = await showDatePicker(
                  context: context,
                  initialDate: from,
                  firstDate: from,
                  lastDate: DateTime(2100),
                );
                if (to == null) {
                  return;
                }
                setState(() {
                  _onDateFilter = '';
                  _fromDateFilter = _toIsoDate(DateTime(from.year, from.month, from.day));
                  _toDateFilter = _toIsoDate(DateTime(to.year, to.month, to.day));
                });
                await _loadWorkloads();
              },
              child: const Text('Date Range'),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _status = '';
                  _search = '';
                  _onDateFilter = '';
                  _fromDateFilter = '';
                  _toDateFilter = '';
                });
                _loadWorkloads();
              },
              child: const Text('Clear Search'),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week_start_date', label: Text('Start')),
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
                                  '${item['assignee_name'] ?? '-'} • ${_displayDateFromIso(item['week_start_date']?.toString() ?? '')} - ${_displayDateFromIso(item['week_end_date']?.toString() ?? '')} • Paid: ${item['paid_amount'] ?? 0}',
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
