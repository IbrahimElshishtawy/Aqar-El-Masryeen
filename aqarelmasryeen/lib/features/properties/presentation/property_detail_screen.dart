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
