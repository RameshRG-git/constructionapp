import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';
import '../../shared/workspace_scope.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  int? _siteId;
  String _status = '';
  String _sortBy = 'recorded_at';
  String _sortOrder = 'desc';
  bool _isLoading = false;
  String? _error;
  double _plannedTotal = 0;
  double _actualTotal = 0;
  double _variance = 0;

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
    await _loadBudgets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final workspaceSiteId = WorkspaceScope.of(context).selectedSiteId;
    if (workspaceSiteId != null && workspaceSiteId != _siteId) {
      _siteId = workspaceSiteId;
      _loadBudgets();
    }
  }

  Future<void> _loadBudgets() async {
    if (_siteId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiRegistry.budgets.listBudgets(
        _siteId!,
        status: _status,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
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
    if (_siteId == null) {
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
                const SizedBox(height: 16),
                TextField(
                  controller: plannedController,
                  decoration: const InputDecoration(labelText: 'Planned Amount'),
                ),
                const SizedBox(height: 16),
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
                  await ApiRegistry.budgets.createBudget(_siteId!, payload);
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
    final workspace = WorkspaceScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Budgets and Reporting', style: theme.textTheme.headlineMedium)),
            FilledButton.icon(
              onPressed: _siteId == null ? null : () => _showBudgetDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Budget'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Budgets stay inside the selected site workspace.', style: theme.textTheme.bodyLarge),
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
        const SizedBox(height: 12),
        Wrap(
          runSpacing: 8,
          spacing: 12,
          children: [
            for (final status in const [
              ('', 'All'),
              ('under_budget', 'Under Budget'),
              ('on_budget', 'On Budget'),
              ('over_budget', 'Over Budget'),
            ])
              ChoiceChip(
                label: Text(status.$2),
                selected: _status == status.$1,
                onSelected: (_) {
                  setState(() => _status = status.$1);
                  _loadBudgets();
                },
              ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'recorded_at', label: Text('Latest')),
                ButtonSegment(value: 'planned_amount', label: Text('Planned')),
                ButtonSegment(value: 'actual_amount', label: Text('Actual')),
                ButtonSegment(value: 'category_name', label: Text('Category')),
              ],
              selected: {_sortBy},
              onSelectionChanged: (selection) {
                setState(() => _sortBy = selection.first);
                _loadBudgets();
              },
            ),
            IconButton(
              tooltip: _sortOrder == 'asc' ? 'Ascending' : 'Descending',
              onPressed: () {
                setState(() => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc');
                _loadBudgets();
              },
              icon: Icon(_sortOrder == 'asc' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
            ),
            Chip(label: Text('Planned: ${_plannedTotal.toStringAsFixed(2)}')),
            Chip(label: Text('Actual: ${_actualTotal.toStringAsFixed(2)}')),
            Chip(label: Text('Variance: ${_variance.toStringAsFixed(2)}')),
            OutlinedButton.icon(onPressed: _loadBudgets, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh')),
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
