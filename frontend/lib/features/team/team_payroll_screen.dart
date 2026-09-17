import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';

/// Sick-leave logging and salary-advance tracking for employees, tenant-wide.
/// Sick days recorded here automatically exclude that day's pay in the site
/// Payments tab. Advances are recovered (FIFO by due date) from an employee's
/// weekly pay once the due date has passed, carrying forward if not fully repaid.
class TeamPayrollScreen extends StatefulWidget {
  const TeamPayrollScreen({super.key});

  @override
  State<TeamPayrollScreen> createState() => _TeamPayrollScreenState();
}

class _TeamPayrollScreenState extends State<TeamPayrollScreen> {
  List<Map<String, dynamic>> _sickLeaves = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _advances = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  String _toIsoDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return '-';
    }
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  double _numOf(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final members = await ApiRegistry.team.listMembers(includeInactive: false, sortBy: 'full_name', sortOrder: 'asc');
      final leaves = await ApiRegistry.teamPayroll.listSickLeaves();
      final advances = await ApiRegistry.teamPayroll.listAdvances();
      setState(() {
        _members = (members['items'] as List<dynamic>? ?? <dynamic>[]).whereType<Map<String, dynamic>>().toList();
        _sickLeaves = (leaves['items'] as List<dynamic>? ?? <dynamic>[]).whereType<Map<String, dynamic>>().toList();
        _advances = (advances['items'] as List<dynamic>? ?? <dynamic>[]).whereType<Map<String, dynamic>>().toList();
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSickLeaveDialog() async {
    int? teamMemberId = _members.isNotEmpty ? _members.first['id'] as int? : null;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    final reasonController = TextEditingController();
    final rootContext = context;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Log Sick Leave'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: teamMemberId,
                        items: _members
                            .map((member) => DropdownMenuItem(
                                  value: member['id'] as int,
                                  child: Text(member['full_name']?.toString() ?? '-'),
                                ))
                            .toList(),
                        onChanged: (value) => setDialogState(() => teamMemberId = value),
                        decoration: const InputDecoration(labelText: 'Employee *'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: _toIsoDate(startDate)),
                        decoration: const InputDecoration(labelText: 'Start Date *', suffixIcon: Icon(Icons.event_rounded)),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              startDate = picked;
                              if (endDate.isBefore(startDate)) {
                                endDate = startDate;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: _toIsoDate(endDate)),
                        decoration: const InputDecoration(labelText: 'End Date *', suffixIcon: Icon(Icons.event_rounded)),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reasonController,
                        decoration: const InputDecoration(labelText: 'Reason (optional)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    if (teamMemberId == null) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text('Please choose an employee.')),
                      );
                      return;
                    }
                    try {
                      await ApiRegistry.teamPayroll.createSickLeave(<String, dynamic>{
                        'team_member_id': teamMemberId,
                        'start_date': _toIsoDate(startDate),
                        'end_date': _toIsoDate(endDate),
                        'reason': reasonController.text.trim(),
                      });
                      if (!rootContext.mounted) {
                        return;
                      }
                      Navigator.pop(context, true);
                    } catch (error) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text('Failed: $error')),
                      );
                    }
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
      await _loadAll();
    }
  }

  Future<void> _deleteSickLeave(Map<String, dynamic> leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Sick Leave'),
        content: Text('Remove the sick leave record for ${leave['employee_name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ApiRegistry.teamPayroll.deleteSickLeave(leave['id'] as int);
    await _loadAll();
  }

  Future<void> _showAdvanceDialog() async {
    int? teamMemberId = _members.isNotEmpty ? _members.first['id'] as int? : null;
    final amountController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    final noteController = TextEditingController();
    final rootContext = context;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Log Salary Advance'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: teamMemberId,
                        items: _members
                            .map((member) => DropdownMenuItem(
                                  value: member['id'] as int,
                                  child: Text(member['full_name']?.toString() ?? '-'),
                                ))
                            .toList(),
                        onChanged: (value) => setDialogState(() => teamMemberId = value),
                        decoration: const InputDecoration(labelText: 'Employee *'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Advance Amount *'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: _toIsoDate(dueDate)),
                        decoration: const InputDecoration(
                          labelText: 'Recovery Due Date *',
                          suffixIcon: Icon(Icons.event_rounded),
                          helperText: 'Recovery starts from the first payroll week on/after this date',
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() => dueDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(labelText: 'Note (optional)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim());
                    if (teamMemberId == null || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text('Choose an employee and enter a valid amount.')),
                      );
                      return;
                    }
                    try {
                      await ApiRegistry.teamPayroll.createAdvance(<String, dynamic>{
                        'team_member_id': teamMemberId,
                        'amount': amount,
                        'due_date': _toIsoDate(dueDate),
                        'note': noteController.text.trim(),
                      });
                      if (!rootContext.mounted) {
                        return;
                      }
                      Navigator.pop(context, true);
                    } catch (error) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text('Failed: $error')),
                      );
                    }
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
      await _loadAll();
    }
  }

  Future<void> _deleteAdvance(Map<String, dynamic> advance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Advance'),
        content: Text(
          'Remove the advance for ${advance['employee_name']}? Any recovery history tied to it will also be removed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ApiRegistry.teamPayroll.deleteAdvance(advance['id'] as int);
    await _loadAll();
  }

  Widget _buildSickLeaveTab(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sick days logged here are excluded from that employee\'s pay for any overlapping workload.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: _members.isEmpty ? null : _showSickLeaveDialog,
              icon: const Icon(Icons.add),
              label: const Text('Log Sick Leave'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: _sickLeaves.isEmpty
                ? const Center(child: Text('No sick leave logged yet'))
                : ListView.separated(
                    itemCount: _sickLeaves.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final leave = _sickLeaves[index];
                      return ListTile(
                        leading: const Icon(Icons.sick_rounded, color: Color(0xFFB45309)),
                        title: Text(leave['employee_name']?.toString() ?? '-'),
                        subtitle: Text(
                          '${_displayDate(leave['start_date']?.toString())} - ${_displayDate(leave['end_date']?.toString())}'
                          '${(leave['reason']?.toString().isNotEmpty ?? false) ? ' • ${leave['reason']}' : ''}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteSickLeave(leave),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvanceTab(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Advances are automatically recovered from weekly pay once the due date has passed; a shortfall carries forward.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: _members.isEmpty ? null : _showAdvanceDialog,
              icon: const Icon(Icons.add),
              label: const Text('Log Advance'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: _advances.isEmpty
                ? const Center(child: Text('No advances logged yet'))
                : ListView.separated(
                    itemCount: _advances.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final advance = _advances[index];
                      final amount = _numOf(advance, 'amount');
                      final recovered = _numOf(advance, 'amount_recovered');
                      final balance = _numOf(advance, 'outstanding_balance');
                      final settled = advance['status'] == 'settled';
                      return ListTile(
                        leading: Icon(
                          Icons.request_quote_rounded,
                          color: settled ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                        title: Text('${advance['employee_name'] ?? '-'} • ${amount.toStringAsFixed(2)}'),
                        subtitle: Text(
                          'Due ${_displayDate(advance['due_date']?.toString())} • Recovered ${recovered.toStringAsFixed(2)} • '
                          'Balance ${balance.toStringAsFixed(2)}'
                          '${(advance['note']?.toString().isNotEmpty ?? false) ? ' • ${advance['note']}' : ''}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              label: Text(settled ? 'Settled' : 'Outstanding'),
                              backgroundColor: settled ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteAdvance(advance),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Payroll: Sick Leave & Advances', style: theme.textTheme.headlineSmall)),
              OutlinedButton.icon(onPressed: _loadAll, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh')),
            ],
          ),
          const SizedBox(height: 8),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sick_rounded), text: 'Sick Leave'),
              Tab(icon: Icon(Icons.request_quote_rounded), text: 'Advances'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : TabBarView(
                        children: [
                          _buildSickLeaveTab(theme),
                          _buildAdvanceTab(theme),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
