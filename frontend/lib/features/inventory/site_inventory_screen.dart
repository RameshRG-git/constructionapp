import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';
import '../../shared/workspace_scope.dart';

class SiteInventoryScreen extends StatefulWidget {
  const SiteInventoryScreen({super.key});

  @override
  State<SiteInventoryScreen> createState() => _SiteInventoryScreenState();
}

class _SiteInventoryScreenState extends State<SiteInventoryScreen> {
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  int? _siteId;
  String _category = '';
  bool? _lowStock;
  String _sortBy = 'item_name';
  String _sortOrder = 'asc';
  bool _isLoading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final siteId = WorkspaceScope.of(context).selectedSiteId;
    if (siteId != _siteId) {
      _siteId = siteId;
      _loadInventory();
    }
  }

  Future<void> _loadInventory() async {
    final siteId = _siteId;
    if (siteId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiRegistry.inventory.listSiteInventory(
        siteId,
        category: _category,
        lowStock: _lowStock,
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

  Future<void> _showItemDialog({Map<String, dynamic>? existing}) async {
    final siteId = _siteId;
    if (siteId == null) {
      return;
    }

    final itemNameController = TextEditingController(text: existing?['item_name']?.toString() ?? '');
    final categoryController = TextEditingController(text: existing?['category']?.toString() ?? '');
    final unitController = TextEditingController(text: existing?['unit_of_measure']?.toString() ?? '');
    final currentController = TextEditingController(text: existing?['current_quantity']?.toString() ?? '0');
    final minimumController = TextEditingController(text: existing?['minimum_quantity']?.toString() ?? '0');
    final storageController = TextEditingController(text: existing?['storage_location']?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Inventory Item' : 'Edit Inventory Item'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: itemNameController, decoration: const InputDecoration(labelText: 'Item Name')),
                  const SizedBox(height: 16),
                  TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                  const SizedBox(height: 16),
                  TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit of Measure')),
                  const SizedBox(height: 16),
                  TextField(controller: currentController, decoration: const InputDecoration(labelText: 'Current Quantity')),
                  const SizedBox(height: 16),
                  TextField(controller: minimumController, decoration: const InputDecoration(labelText: 'Minimum Quantity')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: storageController,
                    decoration: const InputDecoration(labelText: 'Storage Location'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final payload = <String, dynamic>{
                  'item_name': itemNameController.text.trim(),
                  'category': categoryController.text.trim(),
                  'unit_of_measure': unitController.text.trim(),
                  'current_quantity': double.tryParse(currentController.text.trim()) ?? 0,
                  'minimum_quantity': double.tryParse(minimumController.text.trim()) ?? 0,
                  'storage_location': storageController.text.trim(),
                };
                if (existing == null) {
                  await ApiRegistry.inventory.createSiteInventory(siteId, payload);
                } else {
                  await ApiRegistry.inventory.updateInventoryItem(existing['id'] as int, payload);
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
      await _loadInventory();
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
            Expanded(child: Text('Inventory', style: theme.textTheme.headlineMedium)),
            FilledButton.icon(
              onPressed: workspace.selectedSiteId == null ? null : () => _showItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Inventory for the selected site.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 180,
              child: TextField(
                decoration: const InputDecoration(labelText: 'Search category'),
                onChanged: (value) {
                  setState(() => _category = value);
                  _loadInventory();
                },
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All stock'),
                  selected: _lowStock == null,
                  onSelected: (_) {
                    setState(() => _lowStock = null);
                    _loadInventory();
                  },
                ),
                ChoiceChip(
                  label: const Text('Low stock'),
                  selected: _lowStock == true,
                  onSelected: (_) {
                    setState(() => _lowStock = true);
                    _loadInventory();
                  },
                ),
                ChoiceChip(
                  label: const Text('Healthy stock'),
                  selected: _lowStock == false,
                  onSelected: (_) {
                    setState(() => _lowStock = false);
                    _loadInventory();
                  },
                ),
              ],
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'item_name', label: Text('Name')),
                ButtonSegment(value: 'category', label: Text('Category')),
                ButtonSegment(value: 'current_quantity', label: Text('Current Qty')),
                ButtonSegment(value: 'minimum_quantity', label: Text('Minimum Qty')),
              ],
              selected: {_sortBy},
              onSelectionChanged: (selection) {
                setState(() => _sortBy = selection.first);
                _loadInventory();
              },
            ),
            IconButton(
              onPressed: () {
                setState(() => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc');
                _loadInventory();
              },
              icon: Icon(_sortOrder == 'asc' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
            ),
            OutlinedButton.icon(onPressed: _loadInventory, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh')),
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
                        ? const Center(child: Text('No inventory items found'))
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return ListTile(
                                title: Text(item['item_name']?.toString() ?? '-'),
                                subtitle: Text(
                                  '${item['category'] ?? '-'} • ${item['current_quantity']} / ${item['minimum_quantity']} ${item['unit_of_measure'] ?? ''}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(label: Text((item['low_stock'] == true) ? 'Low Stock' : 'Healthy')),
                                    IconButton(
                                      onPressed: () => _showItemDialog(existing: item),
                                      icon: const Icon(Icons.edit_outlined),
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