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
  double _actualTotal = 0;
  double _payrollTotal = 0;
  double _inventoryExpenseTotal = 0;
  double _totalExpense = 0;
  double _remainingBudget = 0;
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
        _actualTotal = (summary['actual_total'] as num?)?.toDouble() ?? 0;
        _payrollTotal = (summary['payroll_total'] as num?)?.toDouble() ?? 0;
        _inventoryExpenseTotal = (summary['inventory_expense_total'] as num?)?.toDouble() ?? 0;
        _totalExpense = (summary['total_expense'] as num?)?.toDouble() ?? 0;
        _remainingBudget = (summary['remaining_budget'] as num?)?.toDouble() ?? 0;
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
                final actualAmount = double.tryParse(actualController.text.trim()) ?? 0;
                final payload = <String, dynamic>{
                  'category_name': categoryController.text.trim(),
                  // Keep planned aligned with actual while planned is hidden from the UI.
                  'planned_amount': actualAmount,
                  'actual_amount': actualAmount,
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

  Future<void> _deleteBudget(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: Text('Delete ${item['category_name'] ?? 'this budget'}? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiRegistry.budgets.deleteBudget(item['id'] as int);
      if (!mounted) {
        return;
      }
      await _loadBudgets();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingColor = _remainingBudget < 0 ? const Color(0xFFB91C1C) : const Color(0xFF0F4C5C);

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEAF6F8), Color(0xFFDDECF0)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCCE2E8)),
          ),
          child: Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Remaining Budget', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                _remainingBudget.toStringAsFixed(2),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: remainingColor,
                ),
              ),
              Chip(label: Text('Actual: ${_actualTotal.toStringAsFixed(2)}')),
              Chip(label: Text('Workload Expense: ${_payrollTotal.toStringAsFixed(2)}')),
              Chip(label: Text('Inventory Expense: ${_inventoryExpenseTotal.toStringAsFixed(2)}')),
              Chip(label: Text('Total Expense: ${_totalExpense.toStringAsFixed(2)}')),
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
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deleteBudget(item),
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
