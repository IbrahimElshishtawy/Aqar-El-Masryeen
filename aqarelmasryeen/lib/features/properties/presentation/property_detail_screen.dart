import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/async_value_view.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/metric_card.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/collections/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/collections/presentation/payment_form_sheet.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/installments/presentation/installment_plan_form_sheet.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_files_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/features/sales/presentation/unit_form_sheet.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final propertyDetailsProvider = StreamProvider.autoDispose.family<PropertyProject?, String>(
  (ref, propertyId) => ref.watch(propertyRepositoryProvider).watchProperty(propertyId),
);
final propertyExpensesProvider = StreamProvider.autoDispose.family<List<ExpenseRecord>, String>(
  (ref, propertyId) => ref.watch(expenseRepositoryProvider).watchByProperty(propertyId),
);
final propertyUnitsProvider = StreamProvider.autoDispose.family<List<UnitSale>, String>(
  (ref, propertyId) => ref.watch(salesRepositoryProvider).watchByProperty(propertyId),
);
final propertyPlansProvider = StreamProvider.autoDispose.family<List<InstallmentPlan>, String>(
  (ref, propertyId) => ref.watch(installmentRepositoryProvider).watchPlansByProperty(propertyId),
);
final propertyInstallmentsProvider =
    StreamProvider.autoDispose.family<List<Installment>, String>(
  (ref, propertyId) =>
      ref.watch(installmentRepositoryProvider).watchInstallmentsByProperty(propertyId),
);
final propertyPaymentsProvider = StreamProvider.autoDispose.family<List<PaymentRecord>, String>(
  (ref, propertyId) => ref.watch(paymentRepositoryProvider).watchByProperty(propertyId),
);
final propertyActivityProvider = StreamProvider.autoDispose.family<List<ActivityLogEntry>, String>(
  (ref, propertyId) => ref.watch(activityRepositoryProvider).watchRecent(propertyId: propertyId),
);
final propertyPartnersProvider = StreamProvider.autoDispose<List<Partner>>(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);
final propertyFilesProvider =
    FutureProvider.autoDispose.family<List<PropertyStorageFile>, String>(
  (ref, propertyId) => ref.watch(propertyFilesRepositoryProvider).listFiles(propertyId),
);

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
  });

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  Future<void> _showSheet(Widget child) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => child,
    );
  }

  Future<void> _confirmDeleteExpense(ExpenseRecord expense) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete expense'),
            content: const Text('This expense will be archived from active views.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    await ref.read(expenseRepositoryProvider).softDelete(expense.id);
    await ref.read(activityRepositoryProvider).log(
      actorId: session.firebaseUser.uid,
      actorName: session.profile?.name ?? 'Partner',
      action: 'expense_deleted',
      entityType: 'expense',
      entityId: expense.id,
      metadata: {'propertyId': widget.propertyId, 'amount': expense.amount},
    );
  }

  Future<void> _editInstallment(Installment installment) async {
    final amountController =
        TextEditingController(text: installment.amount.toStringAsFixed(0));
    final paidController =
        TextEditingController(text: installment.paidAmount.toStringAsFixed(0));
    var dueDate = installment.dueDate;
    var status = installment.status;

    await _showSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dueDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setModalState(() => dueDate = picked);
            }
          }

          return AppFormSheet(
            title: 'Edit installment',
            child: Column(
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: paidController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Paid amount'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Due date'),
                    child: Row(
                      children: [
                        Expanded(child: Text(dueDate.formatShort())),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InstallmentStatus>(
                  value: status,
                  items: InstallmentStatus.values
                      .map((item) => DropdownMenuItem(value: item, child: Text(item.label)))
                      .toList(),
                  onChanged: (value) => setModalState(() => status = value ?? status),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final session = ref.read(authSessionProvider).valueOrNull;
                      if (session == null) return;
                      await ref.read(installmentRepositoryProvider).saveInstallment(
                            Installment(
                              id: installment.id,
                              planId: installment.planId,
                              propertyId: installment.propertyId,
                              unitId: installment.unitId,
                              sequence: installment.sequence,
                              amount: double.tryParse(amountController.text.trim()) ?? installment.amount,
                              paidAmount: double.tryParse(paidController.text.trim()) ?? installment.paidAmount,
                              dueDate: dueDate,
                              status: status,
                              createdAt: installment.createdAt,
                              updatedAt: DateTime.now(),
                              createdBy: installment.createdBy,
                              updatedBy: session.firebaseUser.uid,
                            ),
                          );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save installment'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    amountController.dispose();
    paidController.dispose();
  }

  Future<void> _handleAction(
    _PropertyAction action, {
    PropertyProject? property,
    List<Partner> partners = const [],
    List<UnitSale> units = const [],
    List<Installment> installments = const [],
  }) async {
    switch (action) {
      case _PropertyAction.edit:
        context.push(AppRoutes.editProperty(widget.propertyId));
      case _PropertyAction.addExpense:
        await _showSheet(ExpenseFormSheet(propertyId: widget.propertyId, partners: partners));
      case _PropertyAction.addUnit:
        await _showSheet(UnitFormSheet(propertyId: widget.propertyId));
      case _PropertyAction.addPlan:
        await _showSheet(
          InstallmentPlanFormSheet(propertyId: widget.propertyId, units: units),
        );
      case _PropertyAction.recordPayment:
        await _showSheet(
          PaymentFormSheet(
            propertyId: widget.propertyId,
            units: units,
            installments: installments,
          ),
        );
      case _PropertyAction.archive:
        if (property == null) return;
        final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Archive property'),
                content: Text('Archive ${property.name}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Archive'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!confirmed) return;
        final session = ref.read(authSessionProvider).valueOrNull;
        if (session == null) return;
        await ref.read(propertyRepositoryProvider).archive(
              widget.propertyId,
              actorId: session.firebaseUser.uid,
            );
        await ref.read(activityRepositoryProvider).log(
          actorId: session.firebaseUser.uid,
          actorName: session.profile?.name ?? 'Partner',
          action: 'property_archived',
          entityType: 'property',
          entityId: widget.propertyId,
        );
        if (mounted) context.go(AppRoutes.properties);
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailsProvider(widget.propertyId));
    final expensesAsync = ref.watch(propertyExpensesProvider(widget.propertyId));
    final unitsAsync = ref.watch(propertyUnitsProvider(widget.propertyId));
    final plansAsync = ref.watch(propertyPlansProvider(widget.propertyId));
    final installmentsAsync = ref.watch(propertyInstallmentsProvider(widget.propertyId));
    final paymentsAsync = ref.watch(propertyPaymentsProvider(widget.propertyId));
    final activityAsync = ref.watch(propertyActivityProvider(widget.propertyId));
    final partnersAsync = ref.watch(propertyPartnersProvider);
    final filesAsync = ref.watch(propertyFilesProvider(widget.propertyId));

    final allAsync = [
      propertyAsync,
      expensesAsync,
      unitsAsync,
      plansAsync,
      installmentsAsync,
      paymentsAsync,
      activityAsync,
      partnersAsync,
    ];

    Object? firstError;
    for (final item in allAsync) {
      if (item.hasError) {
        firstError = item.error;
        break;
      }
    }

    if (firstError != null) {
      return AppShellScaffold(
        title: 'Property details',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'Unable to load property',
          message: firstError.toString(),
        ),
      );
    }

    if (allAsync.any((item) => !item.hasValue)) {
      return const AppShellScaffold(
        title: 'Property details',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final property = propertyAsync.value;
    final expenses = expensesAsync.value!;
    final units = unitsAsync.value!;
    final plans = plansAsync.value!;
    final installments = installmentsAsync.value!;
    final payments = paymentsAsync.value!;
    final activity = activityAsync.value!;
    final partners = partnersAsync.value!;

    if (property == null) {
      return const AppShellScaffold(
        title: 'Property details',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'Property not found',
          message: 'This project may have been removed or archived.',
        ),
      );
    }

    final totalExpenses = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final totalSales = units.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final totalCollected = payments.fold<double>(0, (sum, item) => sum + item.amount);
    final overdueCount = installments.where((item) => item.isOverdue).length;
    final dueSoonCount = installments
        .where(
          (item) =>
              item.remainingAmount > 0 &&
              item.dueDate.isAfter(DateTime.now()) &&
              item.dueDate.isBefore(DateTime.now().add(const Duration(days: 7))),
        )
        .length;

    return DefaultTabController(
      length: 8,
      child: AppShellScaffold(
        title: property.name,
        currentIndex: 1,
        actions: [
          PopupMenuButton<_PropertyAction>(
            onSelected: (action) => _handleAction(
              action,
              property: property,
              partners: partners,
              units: units,
              installments: installments,
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _PropertyAction.edit, child: Text('Edit property')),
              PopupMenuItem(value: _PropertyAction.addExpense, child: Text('Add expense')),
              PopupMenuItem(value: _PropertyAction.addUnit, child: Text('Add unit')),
              PopupMenuItem(value: _PropertyAction.addPlan, child: Text('Create installment plan')),
              PopupMenuItem(value: _PropertyAction.recordPayment, child: Text('Record collection')),
              PopupMenuDivider(),
              PopupMenuItem(value: _PropertyAction.archive, child: Text('Archive property')),
            ],
          ),
        ],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.location, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(property.status.label)),
                          Chip(label: Text('Budget ${property.totalBudget.egp}')),
                          Chip(label: Text('Target ${property.totalSalesTarget.egp}')),
                          Chip(label: Text('Due soon $dueSoonCount')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Expenses'),
                Tab(text: 'Sales'),
                Tab(text: 'Installments'),
                Tab(text: 'Collections'),
                Tab(text: 'Reports'),
                Tab(text: 'Files'),
                Tab(text: 'Activity'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(
                    property: property,
                    totalExpenses: totalExpenses,
                    totalSales: totalSales,
                    totalCollected: totalCollected,
                    overdueCount: overdueCount,
                  ),
                  _ExpensesTab(
                    expenses: expenses,
                    partners: partners,
                    onAdd: () => _handleAction(_PropertyAction.addExpense, partners: partners),
                    onEdit: (item) => _showSheet(
                      ExpenseFormSheet(
                        propertyId: widget.propertyId,
                        partners: partners,
                        expense: item,
                      ),
                    ),
                    onDelete: _confirmDeleteExpense,
                  ),
                  _SalesTab(
                    units: units,
                    onAdd: () => _handleAction(_PropertyAction.addUnit),
                    onEdit: (item) => _showSheet(
                      UnitFormSheet(propertyId: widget.propertyId, unit: item),
                    ),
                  ),
                  _InstallmentsTab(
                    plans: plans,
                    installments: installments,
                    units: units,
                    onAddPlan: () => _handleAction(_PropertyAction.addPlan, units: units),
                    onEditInstallment: _editInstallment,
                  ),
                  _CollectionsTab(
                    payments: payments,
                    onAdd: () => _handleAction(
                      _PropertyAction.recordPayment,
                      units: units,
                      installments: installments,
                    ),
                  ),
                  _ReportsTab(
                    totalExpenses: totalExpenses,
                    totalSales: totalSales,
                    totalCollected: totalCollected,
                    units: units,
                    installments: installments,
                    partners: partners,
                    expenses: expenses,
                  ),
                  AsyncValueView<List<PropertyStorageFile>>(
                    value: filesAsync,
                    data: (files) => _FilesTab(files: files),
                  ),
                  _ActivityTab(activity: activity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PropertyAction { edit, addExpense, addUnit, addPlan, recordPayment, archive }

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.property,
    required this.totalExpenses,
    required this.totalSales,
    required this.totalCollected,
    required this.overdueCount,
  });

  final PropertyProject property;
  final double totalExpenses;
  final double totalSales;
  final double totalCollected;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (property.description.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(property.description),
            ),
          ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width < 500 ? 2 : 4,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            MetricCard(label: 'Expenses', value: totalExpenses.egp, icon: Icons.wallet_outlined),
            MetricCard(label: 'Sales value', value: totalSales.egp, icon: Icons.trending_up_outlined),
            MetricCard(label: 'Collected', value: totalCollected.egp, icon: Icons.payments_outlined),
            MetricCard(
              label: 'Overdue',
              value: '$overdueCount',
              icon: Icons.warning_amber_outlined,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }
}

class _ExpensesTab extends StatefulWidget {
  const _ExpensesTab({
    required this.expenses,
    required this.partners,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ExpenseRecord> expenses;
  final List<Partner> partners;
  final VoidCallback onAdd;
  final ValueChanged<ExpenseRecord> onEdit;
  final ValueChanged<ExpenseRecord> onDelete;

  @override
  State<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<_ExpensesTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partnerNames = {for (final item in widget.partners) item.id: item.name};
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.expenses.where((expense) {
      if (query.isEmpty) return true;
      return expense.description.toLowerCase().contains(query) ||
          expense.category.label.toLowerCase().contains(query) ||
          (partnerNames[expense.paidByPartnerId] ?? '').toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search expenses',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyStateView(
                  title: 'No expenses',
                  message: 'Create the first expense for this property.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        title: Text(item.description),
                        subtitle: Text(
                          '${item.category.label} • ${partnerNames[item.paidByPartnerId] ?? 'Partner'} • ${item.date.formatShort()}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            Text(item.amount.egp),
                            IconButton(
                              onPressed: () => widget.onEdit(item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => widget.onDelete(item),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SalesTab extends StatelessWidget {
  const _SalesTab({
    required this.units,
    required this.onAdd,
    required this.onEdit,
  });

  final List<UnitSale> units;
  final VoidCallback onAdd;
  final ValueChanged<UnitSale> onEdit;

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return Center(
        child: FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add first unit'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: units.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add unit'),
            ),
          );
        }
        final item = units[index - 1];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            title: Text(item.unitNumber),
            subtitle: Text(
              '${item.unitType.label} • ${item.customerName.isEmpty ? 'No customer yet' : item.customerName}\n${item.status.label}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.totalPrice.egp),
                TextButton(onPressed: () => onEdit(item), child: const Text('Edit')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InstallmentsTab extends StatelessWidget {
  const _InstallmentsTab({
    required this.plans,
    required this.installments,
    required this.units,
    required this.onAddPlan,
    required this.onEditInstallment,
  });

  final List<InstallmentPlan> plans;
  final List<Installment> installments;
  final List<UnitSale> units;
  final VoidCallback onAddPlan;
  final ValueChanged<Installment> onEditInstallment;

  @override
  Widget build(BuildContext context) {
    final unitLookup = {for (final item in units) item.id: item.unitNumber};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onAddPlan,
            icon: const Icon(Icons.add),
            label: const Text('New plan'),
          ),
        ),
        const SizedBox(height: 12),
        if (plans.isEmpty)
          const EmptyStateView(
            title: 'No installment plans',
            message: 'Generate a payment plan for a sold unit to create the schedule.',
          ),
        for (final plan in plans) ...[
          Card(
            child: ListTile(
              title: Text('Unit ${unitLookup[plan.unitId] ?? plan.unitId}'),
              subtitle: Text(
                '${plan.installmentCount} installments • every ${plan.intervalDays} days',
              ),
              trailing: Text(plan.installmentAmount.egp),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        for (final installment in installments) ...[
          Card(
            child: ListTile(
              title: Text(
                'Installment ${installment.sequence} • ${unitLookup[installment.unitId] ?? '-'}',
              ),
              subtitle: Text(
                '${installment.dueDate.formatShort()} • ${installment.status.label}',
              ),
              trailing: TextButton(
                onPressed: () => onEditInstallment(installment),
                child: Text(installment.remainingAmount.egp),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CollectionsTab extends StatelessWidget {
  const _CollectionsTab({
    required this.payments,
    required this.onAdd,
  });

  final List<PaymentRecord> payments;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Record payment'),
          ),
        ),
        const SizedBox(height: 12),
        if (payments.isEmpty)
          const EmptyStateView(
            title: 'No collections yet',
            message: 'Record the first payment received for this property.',
          ),
        for (final payment in payments) ...[
          Card(
            child: ListTile(
              title: Text(payment.amount.egp),
              subtitle: Text(
                '${payment.paymentMethod.label} • ${payment.receivedAt.formatShort()}',
              ),
              trailing: payment.installmentId == null
                  ? const Text('General')
                  : const Text('Installment'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({
    required this.totalExpenses,
    required this.totalSales,
    required this.totalCollected,
    required this.units,
    required this.installments,
    required this.partners,
    required this.expenses,
  });

  final double totalExpenses;
  final double totalSales;
  final double totalCollected;
  final List<UnitSale> units;
  final List<Installment> installments;
  final List<Partner> partners;
  final List<ExpenseRecord> expenses;

  @override
  Widget build(BuildContext context) {
    final soldUnits = units.where((item) => item.status == UnitStatus.sold).length;
    final overdue = installments.where((item) => item.isOverdue).length;
    final contributionByPartner = <String, double>{};
    for (final expense in expenses) {
      contributionByPartner.update(
        expense.paidByPartnerId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width < 500 ? 2 : 4,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            MetricCard(label: 'Net remaining', value: (totalSales - totalCollected).egp, icon: Icons.timelapse_outlined),
            MetricCard(label: 'Collected', value: totalCollected.egp, icon: Icons.payments_outlined),
            MetricCard(label: 'Sold units', value: '$soldUnits', icon: Icons.home_work_outlined),
            MetricCard(label: 'Overdue', value: '$overdue', icon: Icons.warning_amber_outlined, color: Colors.orange),
          ],
        ),
        const SizedBox(height: 16),
        for (final partner in partners) ...[
          Card(
            child: ListTile(
              title: Text(partner.name),
              subtitle: Text('Share ${(partner.shareRatio * 100).toStringAsFixed(0)}%'),
              trailing: Text((contributionByPartner[partner.id] ?? 0).egp),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _FilesTab extends StatelessWidget {
  const _FilesTab({required this.files});

  final List<PropertyStorageFile> files;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const EmptyStateView(
        title: 'No files uploaded',
        message: 'Storage-backed property files will appear here once uploaded to Firebase Storage.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = files[index];
        return Card(
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(
              '${item.contentType ?? 'file'} • ${(item.sizeBytes / 1024).toStringAsFixed(1)} KB',
            ),
            trailing: Text(item.updatedAt?.formatShort() ?? '-'),
          ),
        );
      },
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.activity});

  final List<ActivityLogEntry> activity;

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return const EmptyStateView(
        title: 'No activity yet',
        message: 'Property actions and security events will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: activity.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = activity[index];
        return Card(
          child: ListTile(
            title: Text('${item.actorName} ${item.action.replaceAll('_', ' ')}'),
            subtitle: Text(item.createdAt.formatWithTime()),
            trailing: Text(item.entityType),
          ),
        );
      },
    );
  }
}
