import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';
import '../../shared/workspace_scope.dart';

class InventoryScreen extends StatefulWidget {
  final int? lockedSiteId;

  const InventoryScreen({super.key, this.lockedSiteId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  int? _siteId;
  final TextEditingController _categoryController = TextEditingController();
  String _category = '';
  bool? _lowStock;
  String _sortBy = 'item_name';
  String _sortOrder = 'asc';
  bool _initialized = false;
  bool _isLoading = false;
  String? _error;

  bool get _siteLocked => widget.lockedSiteId != null;

  @override
  void initState() {
    super.initState();
    if (_siteLocked) {
      _siteId = widget.lockedSiteId;
      _loadInventory();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_siteLocked) {
      return;
    }
    final workspace = WorkspaceScope.of(context);
    if (!_initialized) {
      _initialized = true;
      workspace.ensureLoaded();
    }
    if (_siteId != workspace.selectedSiteId) {
      _siteId = workspace.selectedSiteId;
      _loadInventory();
    }
  }

  Future<void> _loadInventory() async {
    if (_siteId == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiRegistry.inventory.listSiteInventory(
        _siteId!,
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
    if (_siteId == null) {
      return;
    }

    final itemNameController = TextEditingController(text: existing?['item_name']?.toString() ?? '');
    final categoryController = TextEditingController(text: existing?['category']?.toString() ?? '');
    final unitController = TextEditingController(text: existing?['unit_of_measure']?.toString() ?? '');
    final currentController =
        TextEditingController(text: existing?['current_quantity']?.toString() ?? '0');
    final minimumController =
        TextEditingController(text: existing?['minimum_quantity']?.toString() ?? '0');
    final storageController =
        TextEditingController(text: existing?['storage_location']?.toString() ?? '');

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
                  await ApiRegistry.inventory.createSiteInventory(_siteId!, payload);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Inventory', style: theme.textTheme.headlineMedium)),
            FilledButton.icon(
              onPressed: _siteId == null ? null : () => _showItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Simple stock view with one-tap filters for faster decisions.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (!_siteLocked)
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<int>(
                  value: _siteId,
                  items: WorkspaceScope.of(context)
                      .sites
                      .map(
                        (site) => DropdownMenuItem<int>(
                          value: site['id'] as int,
                          child: Text(site['name']?.toString() ?? '-'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _siteId = value;
                    });
                    WorkspaceScope.of(context).selectSite(value);
                    _loadInventory();
                  },
                  decoration: const InputDecoration(labelText: 'Site'),
                ),
              ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                onSubmitted: (value) {
                  _category = value;
                  _loadInventory();
                },
              ),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'low', label: Text('Low')),
                ButtonSegment(value: 'healthy', label: Text('Healthy')),
              ],
              selected: <String>{_lowStock == null ? 'all' : (_lowStock == true ? 'low' : 'healthy')},
              onSelectionChanged: (selection) {
                setState(() {
                  _lowStock = switch (selection.first) {
                    'low' => true,
                    'healthy' => false,
                    _ => null,
                  };
                });
                _loadInventory();
              },
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'item_name', child: Text('Sort: Name')),
                  DropdownMenuItem(value: 'category', child: Text('Sort: Category')),
                  DropdownMenuItem(value: 'current_quantity', child: Text('Sort: Current Qty')),
                  DropdownMenuItem(value: 'minimum_quantity', child: Text('Sort: Minimum Qty')),
                ],
                onChanged: (value) {
                  setState(() => _sortBy = value ?? 'item_name');
                  _loadInventory();
                },
                decoration: const InputDecoration(labelText: 'Sort By'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _categoryController.clear();
                  _category = '';
                  _lowStock = null;
                  _sortBy = 'item_name';
                  _sortOrder = 'asc';
                });
                _loadInventory();
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
                });
                _loadInventory();
              },
              icon: Icon(_sortOrder == 'asc' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
              label: Text(_sortOrder == 'asc' ? 'Asc' : 'Desc'),
            ),
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
