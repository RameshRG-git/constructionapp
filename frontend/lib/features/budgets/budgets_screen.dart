import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<Map<String, dynamic>> _projects = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  int? _projectId;
  bool _isLoading = false;
  String? _error;
  double _plannedTotal = 0;
  double _actualTotal = 0;
  double _variance = 0;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final response = await ApiRegistry.projects.listProjects(sortBy: 'name', sortOrder: 'asc');
    final projects = (response['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    setState(() {
      _projects = projects;
      _projectId = projects.isEmpty ? null : projects.first['id'] as int;
    });
    await _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    if (_projectId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiRegistry.budgets.listBudgets(_projectId!);
      final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
      final summary = (response['summary'] as Map<String, dynamic>? ?? <String, dynamic>{});
      setState(() {
        _items = items;
        _plannedTotal = (summary['planned_total'] as num?)?.toDouble() ?? 0;
        _actualTotal = (summary['actual_total'] as num?)?.toDouble() ?? 0;
        _variance = (summary['variance'] as num?)?.toDouble() ?? 0;
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

  Future<void> _showBudgetDialog({Map<String, dynamic>? existing}) async {
    if (_projectId == null) {
      return;
    }

    final categoryController = TextEditingController(text: existing?['category_name']?.toString() ?? '');
    final plannedController = TextEditingController(text: existing?['planned_amount']?.toString() ?? '0');
    final actualController = TextEditingController(text: existing?['actual_amount']?.toString() ?? '0');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Budget' : 'Edit Budget'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                ),
                TextField(
                  controller: plannedController,
                  decoration: const InputDecoration(labelText: 'Planned Amount'),
                ),
                TextField(
                  controller: actualController,
                  decoration: const InputDecoration(labelText: 'Actual Amount'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final payload = <String, dynamic>{
                  'category_name': categoryController.text.trim(),
                  'planned_amount': double.tryParse(plannedController.text.trim()) ?? 0,
                  'actual_amount': double.tryParse(actualController.text.trim()) ?? 0,
                };
                if (existing == null) {
                  await ApiRegistry.budgets.createBudget(_projectId!, payload);
                } else {
                  await ApiRegistry.budgets.updateBudget(existing['id'] as int, payload);
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
      await _loadBudgets();
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
            Expanded(child: Text('Budgets and Reporting', style: theme.textTheme.headlineMedium)),
            FilledButton.icon(
              onPressed: _projectId == null ? null : () => _showBudgetDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Budget'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Budget data from PostgreSQL with create and modify support.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<int>(
            value: _projectId,
            items: _projects
                .map(
                  (project) => DropdownMenuItem<int>(
                    value: project['id'] as int,
                    child: Text(project['name']?.toString() ?? '-'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _projectId = value;
              });
              _loadBudgets();
            },
            decoration: const InputDecoration(labelText: 'Project'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            Chip(label: Text('Planned: ${_plannedTotal.toStringAsFixed(2)}')),
            Chip(label: Text('Actual: ${_actualTotal.toStringAsFixed(2)}')),
            Chip(label: Text('Variance: ${_variance.toStringAsFixed(2)}')),
            OutlinedButton.icon(onPressed: _loadBudgets, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
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
                        ? const Center(child: Text('No budgets found'))
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return ListTile(
                                title: Text(item['category_name']?.toString() ?? '-'),
                                subtitle: Text(
                                  'Planned ${item['planned_amount']} • Actual ${item['actual_amount']} • Remaining ${item['remaining_amount']}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(label: Text(item['budget_status']?.toString() ?? '-')),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _showBudgetDialog(existing: item),
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
