import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _sites = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  int? _siteId;
  String _search = '';
  String _sortBy = 'item_name';
  String _sortOrder = 'asc';
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    final response = await ApiRegistry.sites.listSites(sortBy: 'name', sortOrder: 'asc');
    final sites = (response['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    setState(() {
      _sites = sites;
      _siteId = null;
    });
    await _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiRegistry.inventory.listInventory(
        siteId: _siteId,
        category: _search,
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
    final targetSiteId = _siteId;
    if (targetSiteId == null) {
      return;
    }

    final itemNameController = TextEditingController(text: existing?['item_name']?.toString() ?? '');
    final categoryController = TextEditingController(text: existing?['category']?.toString() ?? '');
    final unitController = TextEditingController(text: existing?['unit_of_measure']?.toString() ?? '');
    final unitCostController = TextEditingController(text: existing?['unit_cost']?.toString() ?? '0');
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
                  TextField(controller: unitCostController, decoration: const InputDecoration(labelText: 'Unit Cost')),
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
                  'unit_cost': double.tryParse(unitCostController.text.trim()) ?? 0,
                  'current_quantity': double.tryParse(currentController.text.trim()) ?? 0,
                  'minimum_quantity': double.tryParse(minimumController.text.trim()) ?? 0,
                  'storage_location': storageController.text.trim(),
                };
                if (existing == null) {
                  await ApiRegistry.inventory.createSiteInventory(targetSiteId, payload);
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

  Future<void> _deleteInventoryItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Delete ${item['item_name'] ?? 'this item'}? This action cannot be undone.'),
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
      await ApiRegistry.inventory.deleteInventoryItem(item['id'] as int);
      if (!mounted) {
        return;
      }
      await _loadInventory();
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
        Text('Browse all inventory first, then narrow it with site or search filters.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<int?>(
                value: _siteId,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All sites')),
                  ..._sites.map(
                    (site) => DropdownMenuItem<int?>(
                      value: site['id'] as int,
                      child: Text(site['name']?.toString() ?? '-'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _siteId = value);
                  _loadInventory();
                },
                decoration: const InputDecoration(labelText: 'Site'),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                decoration: const InputDecoration(labelText: 'Search inventory'),
                onChanged: (value) {
                  setState(() => _search = value);
                  _loadInventory();
                },
              ),
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
              tooltip: _sortOrder == 'asc' ? 'Ascending' : 'Descending',
              onPressed: () {
                setState(() => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc');
                _loadInventory();
              },
              icon: Icon(
                _sortOrder == 'asc' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              ),
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
                                  '${item['site_name'] ?? 'All sites'} • ${item['category'] ?? '-'} • Cost ${item['unit_cost'] ?? 0} • Value ${item['inventory_value'] ?? 0} • ${item['current_quantity']} / ${item['minimum_quantity']} ${item['unit_of_measure'] ?? ''}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(label: Text((item['low_stock'] == true) ? 'Low Stock' : 'Healthy')),
                                    IconButton(
                                      onPressed: () => _showItemDialog(existing: item),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteInventoryItem(item),
                                      icon: const Icon(Icons.delete_outline),
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
