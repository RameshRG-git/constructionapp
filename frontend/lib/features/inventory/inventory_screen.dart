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
  String _category = '';
  bool? _lowStock;
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
      _siteId = sites.isEmpty ? null : sites.first['id'] as int;
    });
    await _loadInventory();
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
        Text('Live inventory records with filter, sort, add, and modify.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<int>(
                value: _siteId,
                items: _sites
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
                  _loadInventory();
                },
                decoration: const InputDecoration(labelText: 'Site'),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                decoration: const InputDecoration(labelText: 'Category'),
                onChanged: (value) => _category = value,
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                value: _lowStock == null ? 'all' : (_lowStock! ? 'true' : 'false'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Stock')),
                  DropdownMenuItem(value: 'true', child: Text('Low Stock')),
                  DropdownMenuItem(value: 'false', child: Text('Healthy Stock')),
                ],
                onChanged: (value) {
                  setState(() {
                    _lowStock = value == 'all' ? null : value == 'true';
                  });
                },
                decoration: const InputDecoration(labelText: 'Stock State'),
              ),
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
                onChanged: (value) => setState(() => _sortBy = value ?? 'item_name'),
                decoration: const InputDecoration(labelText: 'Sort By'),
              ),
            ),
            FilledButton.icon(onPressed: _loadInventory, icon: const Icon(Icons.filter_alt), label: const Text('Apply')),
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
