import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dailyPayController = TextEditingController();
  final TextEditingController _newRoleTitleController = TextEditingController();
  final TextEditingController _newRoleRateController = TextEditingController();
  final TextEditingController _accessEmailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _roles = <Map<String, dynamic>>[];
  int? _selectedRoleId;
  bool _planAccess = false;
  bool _includeInactive = false;
  String _sortBy = 'full_name';
  String _sortOrder = 'asc';
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSavingRole = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRolesAndMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _dailyPayController.dispose();
    _newRoleTitleController.dispose();
    _newRoleRateController.dispose();
    _accessEmailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  Map<String, dynamic>? get _selectedRole {
    for (final role in _roles) {
      if (role['id'] == _selectedRoleId) {
        return role;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _activeRoles =>
      _roles.where((role) => role['is_active'] == true).toList();

  Future<void> _loadRoles() async {
    final response = await ApiRegistry.team.listRoles(includeInactive: true);
    final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    setState(() {
      _roles = items;
    });
  }

  Future<void> _loadRolesAndMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _loadRoles();
      await _loadMembers();
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

  Future<void> _loadMembers() async {
    try {
      final response = await ApiRegistry.team.listMembers(
        query: _searchController.text.trim(),
        includeInactive: _includeInactive,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _members = items;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    }
  }

  void _applyRoleToMemberForm(int? roleId) {
    setState(() {
      _selectedRoleId = roleId;
    });
    final role = _selectedRole;
    if (role == null) {
      return;
    }
    _titleController.text = role['title']?.toString() ?? '';
    final rate = _asDouble(role['daily_pay_rate']);
    _dailyPayController.text = rate == null ? '' : rate.toStringAsFixed(0);
  }

  Future<void> _createRole() async {
    final title = _newRoleTitleController.text.trim();
    final rate = double.tryParse(_newRoleRateController.text.trim());
    if (title.isEmpty || rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role title and daily pay rate are required.')),
      );
      return;
    }
    setState(() {
      _isSavingRole = true;
    });
    try {
      await ApiRegistry.team.createRole(<String, dynamic>{
        'title': title,
        'daily_pay_rate': rate,
        'is_active': true,
      });
      _newRoleTitleController.clear();
      _newRoleRateController.clear();
      await _loadRoles();
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingRole = false;
      });
    }
  }

  Future<void> _editRole(Map<String, dynamic> role) async {
    final titleController = TextEditingController(text: role['title']?.toString() ?? '');
    final rateController = TextEditingController(text: (_asDouble(role['daily_pay_rate']) ?? 0).toStringAsFixed(0));
    bool active = role['is_active'] == true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Role and Daily Pay'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Role Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Daily Pay Rate'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final rate = double.tryParse(rateController.text.trim());
                if (titleController.text.trim().isEmpty || rate == null) {
                  return;
                }
                await ApiRegistry.team.updateRole(role['id'] as int, <String, dynamic>{
                  'title': titleController.text.trim(),
                  'daily_pay_rate': rate,
                  'is_active': active,
                });
                if (!mounted) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await _loadRoles();
      if (_selectedRoleId == role['id']) {
        _applyRoleToMemberForm(_selectedRoleId);
      }
    }
  }

  Future<void> _createMember() async {
    final name = _nameController.text.trim();
    final title = _titleController.text.trim();
    final payRate = double.tryParse(_dailyPayController.text.trim());
    if (name.isEmpty || title.isEmpty || payRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, title, and daily pay rate are required.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiRegistry.team.createMember(<String, dynamic>{
        'full_name': name,
        'job_title': title,
        'daily_pay_rate': payRate,
        'app_access_planned': _planAccess,
        'access_email': _accessEmailController.text.trim().isEmpty ? null : _accessEmailController.text.trim(),
        'access_role': 'worker',
        'is_active': true,
      });
      if (!mounted) {
        return;
      }
      _nameController.clear();
      _applyRoleToMemberForm(_selectedRoleId);
      _accessEmailController.clear();
      setState(() {
        _planAccess = false;
      });
      await _loadMembers();
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> member) async {
    final id = member['id'] as int;
    final current = member['is_active'] == true;
    await ApiRegistry.team.updateMember(id, <String, dynamic>{'is_active': !current});
    await _loadMembers();
  }

  int? _roleIdForMember(Map<String, dynamic> member) {
    final title = member['job_title']?.toString();
    if (title == null || title.isEmpty) {
      return null;
    }
    for (final role in _activeRoles) {
      if ((role['title']?.toString() ?? '') == title) {
        return role['id'] as int;
      }
    }
    return null;
  }

  Future<void> _editMember(Map<String, dynamic> member) async {
    final nameController = TextEditingController(text: member['full_name']?.toString() ?? '');
    final payController = TextEditingController(
      text: (_asDouble(member['daily_pay_rate']) ?? 0).toStringAsFixed(0),
    );
    int? selectedRoleId = _roleIdForMember(member);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Team Member'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Member Name'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedRoleId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Select title')),
                      ..._activeRoles.map(
                        (role) => DropdownMenuItem<int?>(
                          value: role['id'] as int,
                          child: Text(role['title']?.toString() ?? '-'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRoleId = value;
                        final role = _selectedRoleId == value
                            ? _selectedRole
                            : _activeRoles.where((item) => item['id'] == value).cast<Map<String, dynamic>?>().firstWhere((_) => true, orElse: () => null);
                        final rate = _asDouble(role?['daily_pay_rate']);
                        if (rate != null) {
                          payController.text = rate.toStringAsFixed(0);
                        }
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: payController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Daily Pay Rate'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final payRate = double.tryParse(payController.text.trim());
                  Map<String, dynamic>? selectedRole;
                  if (selectedRoleId != null) {
                    for (final role in _activeRoles) {
                      if (role['id'] == selectedRoleId) {
                        selectedRole = role;
                        break;
                      }
                    }
                  }
                  if (nameController.text.trim().isEmpty || selectedRole == null || payRate == null) {
                    return;
                  }
                  await ApiRegistry.team.updateMember(member['id'] as int, <String, dynamic>{
                    'full_name': nameController.text.trim(),
                    'job_title': selectedRole['title']?.toString() ?? '',
                    'daily_pay_rate': payRate,
                  });
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
      ),
    );

    if (saved == true) {
      await _loadMembers();
    }
  }

  Widget _buildRoleCatalogCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Role and Daily Pay Catalog',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text('Manage default role titles and pay rates used in member and workload creation.'),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _newRoleTitleController,
                    decoration: const InputDecoration(labelText: 'New Role Title'),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _newRoleRateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Daily Pay Rate'),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isSavingRole ? null : _createRole,
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: Text(_isSavingRole ? 'Saving...' : 'Add Role'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_roles.isEmpty)
              const Text('No roles configured yet')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final role in _roles)
                    ActionChip(
                      avatar: Icon(
                        role['is_active'] == true ? Icons.check_circle_outline : Icons.block,
                        size: 18,
                      ),
                      label: Text('${role['title']} - ${role['daily_pay_rate']}/day'),
                      onPressed: () => _editRole(role),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Member Name'),
              ),
            ),
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<int?>(
                initialValue: _selectedRoleId,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Select title')),
                  ..._activeRoles
                      .map(
                        (role) => DropdownMenuItem<int?>(
                          value: role['id'] as int,
                          child: Text(role['title']?.toString() ?? '-'),
                        ),
                      ),
                ],
                onChanged: _applyRoleToMemberForm,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _dailyPayController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Daily Pay Rate'),
              ),
            ),
            SizedBox(
              width: 280,
              child: TextField(
                controller: _accessEmailController,
                enabled: _planAccess,
                decoration: const InputDecoration(
                  labelText: 'Future Login Email (Optional)',
                ),
              ),
            ),
            FilterChip(
              selected: _planAccess,
              onSelected: (selected) {
                setState(() {
                  _planAccess = selected;
                  if (!_planAccess) {
                    _accessEmailController.clear();
                  }
                });
              },
              label: const Text('Plan App Access'),
            ),
            FilledButton.icon(
              onPressed: _isSaving ? null : _createMember,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(labelText: 'Search by name'),
            onChanged: (_) {
              _loadMembers();
            },
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: _sortBy,
          decoration: const InputDecoration(labelText: 'Sort by'),
          items: const [
            DropdownMenuItem(value: 'full_name', child: Text('Name')),
            DropdownMenuItem(value: 'job_title', child: Text('Title')),
            DropdownMenuItem(value: 'daily_pay_rate', child: Text('Pay Rate')),
            DropdownMenuItem(value: 'created_at', child: Text('Created')),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _sortBy = value);
            _loadMembers();
          },
        ),
        IconButton(
          tooltip: _sortOrder == 'asc' ? 'Ascending' : 'Descending',
          onPressed: () {
            setState(() => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc');
            _loadMembers();
          },
          icon: Icon(_sortOrder == 'asc' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
        ),
        FilterChip(
          label: const Text('Include Inactive'),
          selected: _includeInactive,
          onSelected: (selected) {
            setState(() => _includeInactive = selected);
            _loadMembers();
          },
        ),
        OutlinedButton.icon(
          onPressed: _loadRolesAndMembers,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    return Expanded(
      child: Card(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _members.isEmpty
                    ? const Center(child: Text('No team members added yet'))
                    : ListView.separated(
                        itemCount: _members.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final hasPlannedAccess = member['app_access_planned'] == true;
                          final active = member['is_active'] == true;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEAF2F4),
                              child: Text(
                                (member['full_name']?.toString().isNotEmpty ?? false)
                                    ? member['full_name'].toString().substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(member['full_name']?.toString() ?? '-'),
                            subtitle: Text(
                              '${member['job_title'] ?? '-'} | Pay: ${member['daily_pay_rate'] ?? '-'} / day',
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Chip(label: Text(active ? 'Active' : 'Inactive')),
                                if (hasPlannedAccess) const Chip(label: Text('Access Planned')),
                                IconButton(
                                  onPressed: () => _editMember(member),
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit member',
                                ),
                                TextButton(
                                  onPressed: () => _toggleActive(member),
                                  child: Text(active ? 'Deactivate' : 'Activate'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildMembersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMemberFormCard(),
        const SizedBox(height: 14),
        _buildMemberFilters(),
        const SizedBox(height: 14),
        _buildMembersList(),
      ],
    );
  }

  Widget _buildRoleCatalogTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleCatalogCard(),
        ],
      ),
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
          Text('Team Management', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Manage team members and the role/pay catalog centrally across all sites.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.badge_rounded), text: 'Members'),
              Tab(icon: Icon(Icons.payments_rounded), text: 'Role & Daily Pay Catalog'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _buildMembersTab(),
                _buildRoleCatalogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}