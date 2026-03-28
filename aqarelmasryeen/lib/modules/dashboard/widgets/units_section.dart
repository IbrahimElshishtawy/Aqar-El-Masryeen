import 'package:aqarelmasryeen/core/responsive/app_breakpoints.dart';
import 'package:aqarelmasryeen/data/models/workspace_models.dart';
import 'package:aqarelmasryeen/data/repositories/workspace_repository.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/workspace_ui.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_card.dart';
import 'package:aqarelmasryeen/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UnitsSection extends StatefulWidget {
  const UnitsSection({super.key});

  @override
  State<UnitsSection> createState() => _UnitsSectionState();
}

class _UnitsSectionState extends State<UnitsSection> {
  final workspace = Get.find<WorkspaceRepository>();
  final searchController = TextEditingController();
  UnitStatus? statusFilter;

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final items = workspace.units.where((unit) {
      final matchesQuery = unit.unitNumber.toLowerCase().contains(query);
      final matchesStatus = statusFilter == null || unit.status == statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    return SectionScaffold(
      title: 'units'.tr,
      subtitle: 'units_subtitle'.tr,
      action: workspace.canManageProperties
          ? SizedBox(
              width: 160,
              child: AppButton(
                label: 'add_unit'.tr,
                onPressed: () => _showUnitDialog(context),
              ),
            )
          : null,
      child: Column(
        children: [
          AppCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: AppTextField(
                    controller: searchController,
                    label: 'search'.tr,
                    prefixIcon: const Icon(Icons.search_rounded),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<UnitStatus?>(
                    value: statusFilter,
                    items: [
                      DropdownMenuItem<UnitStatus?>(
                        value: null,
                        child: Text('all_statuses'.tr),
                      ),
                      ...UnitStatus.values.map(
                        (status) => DropdownMenuItem<UnitStatus?>(
                          value: status,
                          child: Text(status.labelKey.tr),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => statusFilter = value),
                    decoration: InputDecoration(labelText: 'status'.tr),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (context.isDesktop)
            AppCard(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('unit_number'.tr)),
                    DataColumn(label: Text('property'.tr)),
                    DataColumn(label: Text('floor'.tr)),
                    DataColumn(label: Text('type'.tr)),
                    DataColumn(label: Text('area'.tr)),
                    DataColumn(label: Text('price'.tr)),
                    DataColumn(label: Text('status'.tr)),
                  ],
                  rows: items
                      .map(
                        (unit) => DataRow(
                          onSelectChanged: workspace.canManageProperties
                              ? (_) => _showUnitDialog(context, unit: unit)
                              : null,
                          cells: [
                            DataCell(Text(unit.unitNumber)),
                            DataCell(Text(workspace.propertyNameById(unit.propertyId))),
                            DataCell(Text('${unit.floorNumber}')),
                            DataCell(Text(unit.type.labelKey.tr)),
                            DataCell(Text('${unit.area}')),
                            DataCell(Text(formatCurrency(unit.price))),
                            DataCell(Text(unit.status.labelKey.tr)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: items
                  .map(
                    (unit) => SizedBox(
                      width: double.infinity,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              unit.unitNumber,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(workspace.propertyNameById(unit.propertyId)),
                            const SizedBox(height: 8),
                            Text(
                              '${unit.type.labelKey.tr} • ${formatCurrency(unit.price)} • ${unit.status.labelKey.tr}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

Future<void> _showUnitDialog(BuildContext context, {UnitRecord? unit}) async {
  final workspace = Get.find<WorkspaceRepository>();
  final unitNumberController = TextEditingController(text: unit?.unitNumber ?? '');
  final floorController = TextEditingController(text: '${unit?.floorNumber ?? 0}');
  final areaController = TextEditingController(text: '${unit?.area ?? 0}');
  final priceController = TextEditingController(text: '${unit?.price ?? 0}');
  final notesController = TextEditingController(text: unit?.notes ?? '');
  var propertyId = unit?.propertyId ?? workspace.properties.first.id;
  var type = unit?.type ?? UnitType.apartment;
  var status = unit?.status ?? UnitStatus.available;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(unit == null ? 'add_unit'.tr : 'edit_unit'.tr),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: propertyId,
                    items: workspace.properties
                        .map(
                          (property) => DropdownMenuItem(
                            value: property.id,
                            child: Text(property.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => propertyId = value!),
                    decoration: InputDecoration(labelText: 'property'.tr),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(controller: unitNumberController, label: 'unit_number'.tr),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: floorController,
                    label: 'floor'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UnitType>(
                    value: type,
                    items: UnitType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.labelKey.tr),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => type = value!),
                    decoration: InputDecoration(labelText: 'type'.tr),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: areaController,
                    label: 'area'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: priceController,
                    label: 'price'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UnitStatus>(
                    value: status,
                    items: UnitStatus.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.labelKey.tr),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => status = value!),
                    decoration: InputDecoration(labelText: 'status'.tr),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: notesController,
                    label: 'notes'.tr,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              onPressed: () async {
                await workspace.addOrUpdateUnit(
                  UnitRecord(
                    id: unit?.id ?? 'unit_${DateTime.now().microsecondsSinceEpoch}',
                    propertyId: propertyId,
                    unitNumber: unitNumberController.text.trim(),
                    floorNumber: int.tryParse(floorController.text.trim()) ?? 0,
                    type: type,
                    area: double.tryParse(areaController.text.trim()) ?? 0,
                    price: double.tryParse(priceController.text.trim()) ?? 0,
                    status: status,
                    notes: notesController.text.trim(),
                    saleContractId: unit?.saleContractId,
                    createdAt: unit?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: Text('save'.tr),
            ),
          ],
        ),
      );
    },
  );
}
