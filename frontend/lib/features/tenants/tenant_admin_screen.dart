import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';

class TenantAdminScreen extends StatefulWidget {
  const TenantAdminScreen({super.key});

  @override
  State<TenantAdminScreen> createState() => _TenantAdminScreenState();
}

class _TenantAdminScreenState extends State<TenantAdminScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _logoController = TextEditingController();
  final TextEditingController _primaryController = TextEditingController(text: '#0F4C5C');
  final TextEditingController _secondaryController = TextEditingController(text: '#2C7A7B');

  List<Map<String, dynamic>> _tenants = <Map<String, dynamic>>[];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiRegistry.tenants.listTenants();
      final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _tenants = items;
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

  Future<void> _createTenant() async {
    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'slug': _slugController.text.trim(),
      'logo_url': _logoController.text.trim().isEmpty ? null : _logoController.text.trim(),
      'primary_color': _primaryController.text.trim(),
      'secondary_color': _secondaryController.text.trim(),
      'is_active': true,
    };
    await ApiRegistry.tenants.createTenant(payload);
    if (!mounted) {
      return;
    }
    _nameController.clear();
    _slugController.clear();
    _logoController.clear();
    await _loadTenants();
  }

  void _switchTenant(String slug) {
    ApiRegistry.client.setTenantName(slug);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Active tenant switched to $slug')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tenant Administration', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Create tenants and switch active tenant branding/runtime context.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tenant Name'),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _slugController,
                decoration: const InputDecoration(labelText: 'Tenant Slug'),
              ),
            ),
            SizedBox(
              width: 320,
              child: TextField(
                controller: _logoController,
                decoration: const InputDecoration(labelText: 'Logo URL'),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _primaryController,
                decoration: const InputDecoration(labelText: 'Primary Color'),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _secondaryController,
                decoration: const InputDecoration(labelText: 'Secondary Color'),
              ),
            ),
            FilledButton.icon(
              onPressed: _createTenant,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Create Tenant'),
            ),
            OutlinedButton.icon(
              onPressed: _loadTenants,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Card(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _tenants.isEmpty
                        ? const Center(child: Text('No tenants configured'))
                        : ListView.separated(
                            itemCount: _tenants.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final tenant = _tenants[index];
                              final slug = tenant['slug']?.toString() ?? '-';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFEAF2F4),
                                  child: Text(
                                    slug.isEmpty ? '?' : slug.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                title: Text(tenant['name']?.toString() ?? '-'),
                                subtitle: Text(
                                  'slug: $slug | schema: ${tenant['schema_name'] ?? '-'} | prefix: ${tenant['table_prefix'] ?? '-'}',
                                ),
                                trailing: FilledButton(
                                  onPressed: slug == '-' ? null : () => _switchTenant(slug),
                                  child: const Text('Use Tenant'),
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