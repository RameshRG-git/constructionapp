import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';

class TenantAdminScreen extends StatefulWidget {
  const TenantAdminScreen({super.key});

  @override
  State<TenantAdminScreen> createState() => _TenantAdminScreenState();
}

class _TenantAdminScreenState extends State<TenantAdminScreen> {
  static const List<String> _accessRoles = [
    'admin',
    'tenant_admin',
    'project_management',
    'site_operations',
    'warehouse_control',
    'finance_review',
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _logoController = TextEditingController();
  final TextEditingController _primaryController = TextEditingController(text: '#0F4C5C');
  final TextEditingController _secondaryController = TextEditingController(text: '#2C7A7B');

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<Map<String, dynamic>> _tenants = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _mappings = <Map<String, dynamic>>[];

  int? _mappingUserId;
  int? _mappingTenantId;
  String _mappingRole = 'site_operations';

  bool _isLoading = false;
  bool _isSavingUser = false;
  bool _isSavingMapping = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _logoController.dispose();
    _primaryController.dispose();
    _secondaryController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _notify(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tenantResponse = await ApiRegistry.tenants.listTenants();
      final userResponse = await ApiRegistry.users.listUsers();
      final mappingResponse = await ApiRegistry.users.listUserTenants();
      if (!mounted) {
        return;
      }
      setState(() {
        _tenants = (tenantResponse['items'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();
        _users = (userResponse['items'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();
        _mappings = (mappingResponse['items'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    try {
      await ApiRegistry.tenants.createTenant(payload);
      _nameController.clear();
      _slugController.clear();
      _logoController.clear();
      await _loadAll();
      _notify('Tenant created');
    } catch (error) {
      _notify('Create tenant failed: $error');
    }
  }

  void _switchTenant(String slug) {
    ApiRegistry.client.setTenantName(slug);
    _notify('Active tenant switched to $slug');
  }

  Future<void> _createUser() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _fullNameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _notify('Username, email, full name and password are required.');
      return;
    }

    setState(() => _isSavingUser = true);
    try {
      await ApiRegistry.users.createUser(<String, dynamic>{
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'password': _passwordController.text,
        'is_active': true,
      });
      _usernameController.clear();
      _emailController.clear();
      _fullNameController.clear();
      _passwordController.clear();
      await _loadAll();
      _notify('User created');
    } catch (error) {
      _notify('Create user failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isSavingUser = false);
      }
    }
  }

  Future<void> _toggleUserActive(Map<String, dynamic> user) async {
    try {
      await ApiRegistry.users.updateUser(
        user['id'] as int,
        <String, dynamic>{'is_active': !(user['is_active'] == true)},
      );
      await _loadAll();
    } catch (error) {
      _notify('Update user failed: $error');
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user['username'] ?? 'this user'}? Tenant mappings will also be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ApiRegistry.users.deleteUser(user['id'] as int);
      await _loadAll();
      _notify('User deleted');
    } catch (error) {
      _notify('Delete user failed: $error');
    }
  }

  Future<void> _mapUserToTenant() async {
    if (_mappingUserId == null || _mappingTenantId == null) {
      _notify('Select both a user and a tenant.');
      return;
    }

    setState(() => _isSavingMapping = true);
    try {
      await ApiRegistry.users.mapUserToTenant(<String, dynamic>{
        'user_id': _mappingUserId,
        'tenant_id': _mappingTenantId,
        'access_role': _mappingRole,
        'is_active': true,
      });
      await _loadAll();
      _notify('User mapped to tenant');
    } catch (error) {
      _notify('Mapping failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isSavingMapping = false);
      }
    }
  }

  Future<void> _updateMappingRole(Map<String, dynamic> mapping, String role) async {
    try {
      await ApiRegistry.users.updateUserTenant(
        mapping['id'] as int,
        <String, dynamic>{'access_role': role},
      );
      await _loadAll();
    } catch (error) {
      _notify('Update mapping failed: $error');
    }
  }

  Future<void> _removeMapping(Map<String, dynamic> mapping) async {
    try {
      await ApiRegistry.users.deleteUserTenant(mapping['id'] as int);
      await _loadAll();
      _notify('Mapping removed');
    } catch (error) {
      _notify('Remove mapping failed: $error');
    }
  }

  Widget _buildStateWrapper(Widget child, {required bool isEmpty, required String emptyText}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (isEmpty) {
      return Center(child: Text(emptyText));
    }
    return child;
  }

  Widget _buildTenantsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Card(
            child: _buildStateWrapper(
              ListView.separated(
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
              isEmpty: _tenants.isEmpty,
              emptyText: 'No tenants configured',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
            ),
            SizedBox(
              width: 260,
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ),
            SizedBox(
              width: 240,
              child: TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  helperText: 'Minimum 8 characters',
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _isSavingUser ? null : _createUser,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Create User'),
            ),
            OutlinedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Card(
            child: _buildStateWrapper(
              ListView.separated(
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final tenants = (user['tenants'] as List<dynamic>? ?? <dynamic>[])
                      .whereType<Map<String, dynamic>>()
                      .map((link) => link['tenant_slug']?.toString() ?? '-')
                      .join(', ');
                  final isActive = user['is_active'] == true;
                  return ListTile(
                    leading: const Icon(Icons.account_circle_rounded),
                    title: Text('${user['full_name'] ?? '-'} (${user['username'] ?? '-'})'),
                    subtitle: Text(
                      '${user['email'] ?? '-'} • tenants: ${tenants.isEmpty ? 'none' : tenants}',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(label: Text(isActive ? 'Active' : 'Inactive')),
                        IconButton(
                          tooltip: isActive ? 'Deactivate' : 'Activate',
                          icon: Icon(isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded),
                          onPressed: () => _toggleUserActive(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteUser(user),
                        ),
                      ],
                    ),
                  );
                },
              ),
              isEmpty: _users.isEmpty,
              emptyText: 'No users created yet',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMappingTab() {
    final userIds = _users.map((user) => user['id'] as int).toSet();
    final tenantIds = _tenants.map((tenant) => tenant['id'] as int).toSet();
    final selectedUserId = userIds.contains(_mappingUserId) ? _mappingUserId : null;
    final selectedTenantId = tenantIds.contains(_mappingTenantId) ? _mappingTenantId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<int?>(
                initialValue: selectedUserId,
                decoration: const InputDecoration(labelText: 'User'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Select user')),
                  ..._users.map(
                    (user) => DropdownMenuItem<int?>(
                      value: user['id'] as int,
                      child: Text('${user['full_name'] ?? '-'} (${user['username'] ?? '-'})'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _mappingUserId = value),
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<int?>(
                initialValue: selectedTenantId,
                decoration: const InputDecoration(labelText: 'Tenant'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Select tenant')),
                  ..._tenants.map(
                    (tenant) => DropdownMenuItem<int?>(
                      value: tenant['id'] as int,
                      child: Text(tenant['name']?.toString() ?? '-'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _mappingTenantId = value),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                initialValue: _mappingRole,
                decoration: const InputDecoration(labelText: 'Access Role'),
                items: _accessRoles
                    .map((role) => DropdownMenuItem<String>(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) => setState(() => _mappingRole = value ?? 'site_operations'),
              ),
            ),
            FilledButton.icon(
              onPressed: _isSavingMapping ? null : _mapUserToTenant,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Map User to Tenant'),
            ),
            OutlinedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Card(
            child: _buildStateWrapper(
              ListView.separated(
                itemCount: _mappings.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final mapping = _mappings[index];
                  final role = mapping['access_role']?.toString() ?? 'site_operations';
                  return ListTile(
                    leading: const Icon(Icons.link_rounded),
                    title: Text('${mapping['full_name'] ?? '-'} (${mapping['username'] ?? '-'})'),
                    subtitle: Text(
                      'tenant: ${mapping['tenant_name'] ?? mapping['tenant_slug'] ?? '-'} • slug: ${mapping['tenant_slug'] ?? '-'}',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            initialValue: _accessRoles.contains(role) ? role : _accessRoles.first,
                            decoration: const InputDecoration(labelText: 'Role', isDense: true),
                            items: _accessRoles
                                .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _updateMappingRole(mapping, value);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove mapping',
                          icon: const Icon(Icons.link_off_rounded),
                          onPressed: () => _removeMapping(mapping),
                        ),
                      ],
                    ),
                  );
                },
              ),
              isEmpty: _mappings.isEmpty,
              emptyText: 'No user-tenant mappings yet',
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
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tenant Administration', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Create tenants, manage application users, and map users to tenants.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.business_rounded), text: 'Tenants'),
              Tab(icon: Icon(Icons.manage_accounts_rounded), text: 'Users'),
              Tab(icon: Icon(Icons.link_rounded), text: 'User Mapping'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _buildTenantsTab(),
                _buildUsersTab(),
                _buildMappingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}