import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';
import '../../shared/workspace_scope.dart';

/// Weekly payroll for a site. The payroll cycle runs Sunday -> Saturday and the
/// figures are derived from the workload (work assignment) records for the week.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  static const List<String> _weekdayLabels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _monthLabels = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const String _statusAll = 'all';

  int? _siteId;
  DateTime _weekStart = _weekStartFor(DateTime.now());
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  Map<String, dynamic> _summary = <String, dynamic>{};
  String _search = '';
  String _statusFilter = _statusAll;
  bool _isLoading = false;
  String? _error;

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  /// Sunday that starts the payroll week containing [value].
  static DateTime _weekStartFor(DateTime value) {
    final day = _dateOnly(value);
    return day.subtract(Duration(days: day.weekday % 7));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  bool get _isCurrentWeek => _weekStart == _weekStartFor(DateTime.now());

  bool get _isFutureWeek => _weekStart.isAfter(_weekStartFor(DateTime.now()));

  String _toIsoDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _shortDate(DateTime date) =>
      '${_weekdayLabels[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')} ${_monthLabels[date.month - 1]}';

  String _weekLabel() => '${_shortDate(_weekStart)} - ${_shortDate(_weekEnd)} ${_weekEnd.year}';

  String _money(num? value) => (value ?? 0).toDouble().toStringAsFixed(2);

  double _numOf(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workspaceSiteId = WorkspaceScope.of(context).selectedSiteId;
      if (!mounted) {
        return;
      }
      setState(() => _siteId = workspaceSiteId);
      _loadPayroll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final workspaceSiteId = WorkspaceScope.of(context).selectedSiteId;
    if (workspaceSiteId != null && workspaceSiteId != _siteId) {
      _siteId = workspaceSiteId;
      _loadPayroll();
    }
  }

  Future<void> _loadPayroll() async {
    if (_siteId == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiRegistry.payroll.getWeeklyPayroll(
        _siteId!,
        weekStart: _toIsoDate(_weekStart),
      );
      _applyResponse(response);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyResponse(Map<String, dynamic> response) {
    if (!mounted) {
      return;
    }
    final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    setState(() {
      _items = items;
      _summary = response['summary'] as Map<String, dynamic>? ?? <String, dynamic>{};
    });
  }

  List<Map<String, dynamic>> get _visibleItems {
    final search = _search.trim().toLowerCase();
    return _items.where((item) {
      final status = item['status']?.toString() ?? 'pending';
      if (_statusFilter != _statusAll && status != _statusFilter) {
        return false;
      }
      if (search.isEmpty) {
        return true;
      }
      final name = item['employee_name']?.toString().toLowerCase() ?? '';
      final role = item['role_title']?.toString().toLowerCase() ?? '';
      return name.contains(search) || role.contains(search);
    }).toList();
  }

  void _shiftWeek(int weeks) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));
    _loadPayroll();
  }

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pick any day in the payroll week',
    );
    if (picked == null) {
      return;
    }
    setState(() => _weekStart = _weekStartFor(picked));
    await _loadPayroll();
  }

  Future<void> _showPaymentDialog(Map<String, dynamic> row) async {
    if (_siteId == null) {
      return;
    }
    final rootContext = context;
    final earned = _numOf(row, 'earned_amount');
    final outstanding = _numOf(row, 'outstanding_amount');
    final amountController = TextEditingController(
      text: (outstanding > 0 ? outstanding : earned).toStringAsFixed(2),
    );
    final noteController = TextEditingController(text: row['note']?.toString() ?? '');
    String method = row['payment_method']?.toString() ?? 'cash';
    DateTime paidOn = DateTime.tryParse(row['paid_on']?.toString() ?? '') ?? _dateOnly(DateTime.now());

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Pay ${row['employee_name'] ?? '-'}'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Week ${_weekLabel()}'),
                      const SizedBox(height: 4),
                      Text(
                        '${row['days_worked'] ?? 0} day(s) worked • Earned ${_money(earned)} • Outstanding ${_money(outstanding)}',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Amount to pay *'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: method,
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                          DropdownMenuItem(value: 'upi', child: Text('UPI')),
                          DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (value) => setDialogState(() => method = value ?? 'cash'),
                        decoration: const InputDecoration(labelText: 'Payment method'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: _toIsoDate(paidOn)),
                        decoration: const InputDecoration(
                          labelText: 'Paid on',
                          suffixIcon: Icon(Icons.event_rounded),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: paidOn,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() => paidOn = _dateOnly(picked));
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(labelText: 'Note (optional)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim());
                    if (amount == null || amount < 0) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount.')),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                    try {
                      final response = await ApiRegistry.payroll.recordPayment(_siteId!, <String, dynamic>{
                        'week_start': _toIsoDate(_weekStart),
                        'employee_name': row['employee_name'],
                        'role_title': row['role_title'],
                        'days_worked': row['days_worked'],
                        'earned_amount': earned,
                        'paid_amount': amount,
                        'payment_method': method,
                        'paid_on': _toIsoDate(paidOn),
                        'note': noteController.text.trim(),
                      });
                      _applyResponse(response);
                    } catch (error) {
                      if (!rootContext.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text('Payment failed: $error')),
                      );
                    }
                  },
                  child: const Text('Record Payment'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded.')),
      );
    }
  }

  Future<void> _payAllOutstanding() async {
    if (_siteId == null) {
      return;
    }
    final outstanding = _numOf(_summary.cast<String, dynamic>(), 'total_outstanding');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pay all outstanding'),
          content: Text(
            'Mark every unpaid employee for ${_weekLabel()} as fully paid? Total ${_money(outstanding)}.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pay All')),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final response = await ApiRegistry.payroll.payAll(_siteId!, <String, dynamic>{
        'week_start': _toIsoDate(_weekStart),
        'payment_method': 'cash',
      });
      _applyResponse(response);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk payment failed: $error')),
      );
    }
  }

  Widget _buildWeekPicker(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous week',
              onPressed: () => _shiftWeek(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            InkWell(
              onTap: _pickWeek,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.date_range_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _weekLabel(),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next week',
              onPressed: _isFutureWeek ? null : () => _shiftWeek(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            if (_isCurrentWeek)
              const Chip(label: Text('Current week'))
            else
              TextButton.icon(
                onPressed: () {
                  setState(() => _weekStart = _weekStartFor(DateTime.now()));
                  _loadPayroll();
                },
                icon: const Icon(Icons.today_rounded),
                label: const Text('This week'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final palette = <String, (Color, String)>{
      'paid': (const Color(0xFF15803D), 'Paid'),
      'partial': (const Color(0xFFB45309), 'Partial'),
      'pending': (const Color(0xFFB91C1C), 'Pending'),
    };
    final entry = palette[status] ?? palette['pending']!;
    return Chip(
      label: Text(entry.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: entry.$1,
      side: BorderSide.none,
    );
  }

  Widget _buildEmployeeTile(Map<String, dynamic> row, ThemeData theme) {
    final status = row['status']?.toString() ?? 'pending';
    final assignments = (row['assignments'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    return ExpansionTile(
      leading: const Icon(Icons.person_rounded),
      title: Text(row['employee_name']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        '${row['role_title'] ?? 'team'} • ${row['days_worked'] ?? 0} day(s) • Rate ${_money(row['daily_rate'] as num?)}/day',
      ),
      trailing: Wrap(
        spacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_money(row['earned_amount'] as num?), style: theme.textTheme.titleMedium),
              Text('Paid ${_money(row['paid_amount'] as num?)}', style: theme.textTheme.bodySmall),
            ],
          ),
          _statusChip(status),
          IconButton(
            tooltip: 'Record payment',
            icon: const Icon(Icons.payments_outlined),
            onPressed: () => _showPaymentDialog(row),
          ),
        ],
      ),
      childrenPadding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
      children: [
        for (final assignment in assignments)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(assignment['title']?.toString() ?? '-'),
            subtitle: Text(
              '${assignment['start_date']} to ${assignment['end_date']} • ${assignment['days_in_week']} day(s) in this week',
            ),
            trailing: Text(_money(assignment['amount'] as num?)),
          ),
        if (row['paid_on'] != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Paid on ${row['paid_on']} via ${row['payment_method'] ?? '-'}'
              '${(row['note']?.toString().isNotEmpty ?? false) ? ' • ${row['note']}' : ''}',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildTotalsBar(ThemeData theme) {
    final totalPayable = _numOf(_summary.cast<String, dynamic>(), 'total_earned');
    final totalPaid = _numOf(_summary.cast<String, dynamic>(), 'total_paid');
    final outstanding = _numOf(_summary.cast<String, dynamic>(), 'total_outstanding');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C5C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _totalBlock(theme, 'Total payable', totalPayable),
          _totalBlock(theme, 'Total paid', totalPaid),
          _totalBlock(theme, 'Outstanding', outstanding),
          FilledButton.icon(
            onPressed: outstanding <= 0 ? null : _payAllOutstanding,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F4C5C),
            ),
            icon: const Icon(Icons.done_all_rounded),
            label: const Text('Pay All Outstanding'),
          ),
        ],
      ),
    );
  }

  Widget _totalBlock(ThemeData theme, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
        const SizedBox(height: 2),
        Text(
          _money(value),
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _visibleItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Payments', style: theme.textTheme.headlineMedium)),
            OutlinedButton.icon(
              onPressed: _loadPayroll,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Weekly payroll (Sunday to Saturday), calculated from the workloads recorded for this site.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _buildWeekPicker(theme),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                decoration: const InputDecoration(labelText: 'Search employee or role'),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            for (final status in const [
              (_statusAll, 'All'),
              ('pending', 'Pending'),
              ('partial', 'Partial'),
              ('paid', 'Paid'),
            ])
              ChoiceChip(
                label: Text(status.$2),
                selected: _statusFilter == status.$1,
                onSelected: (_) => setState(() => _statusFilter = status.$1),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _items.isEmpty
                                    ? 'No one worked on this site during ${_weekLabel()}.'
                                    : 'No employees match the current filters.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) => _buildEmployeeTile(items[index], theme),
                          ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTotalsBar(theme),
      ],
    );
  }
}
