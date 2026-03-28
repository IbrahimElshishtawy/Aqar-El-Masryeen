import 'package:aqarelmasryeen/core/responsive/app_breakpoints.dart';
import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/data/models/workspace_models.dart';
import 'package:aqarelmasryeen/data/repositories/workspace_repository.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/workspace_ui.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_card.dart';
import 'package:aqarelmasryeen/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PropertiesSection extends StatelessWidget {
  const PropertiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Get.find<WorkspaceRepository>();

    return SectionScaffold(
      title: 'properties'.tr,
      subtitle: 'properties_subtitle'.tr,
      action: workspace.canManageProperties
          ? SizedBox(
              width: 160,
              child: AppButton(
                label: 'add_property'.tr,
                onPressed: () => _showPropertyDialog(context),
              ),
            )
          : null,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: workspace.properties
            .map(
              (property) => SizedBox(
                width: context.isDesktop ? 380 : double.infinity,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${property.code} • ${property.location}'),
                      const SizedBox(height: 10),
                      Text(
                        property.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('${property.floorsCount} ${'floors'.tr}')),
                          Chip(label: Text('${property.unitsCount} ${'units'.tr}')),
                          Chip(label: Text(property.status.labelKey.tr)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: property.assignedUserIds
                            .map((id) => Chip(label: Text(workspace.userNameById(id))))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'edit'.tr,
                          variant: AppButtonVariant.secondary,
                          onPressed: workspace.canManageProperties
                              ? () => _showPropertyDialog(context, property: property)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

Future<void> _showPropertyDialog(
  BuildContext context, {
  PropertyRecord? property,
}) async {
  final workspace = Get.find<WorkspaceRepository>();
  final nameController = TextEditingController(text: property?.name ?? '');
  final codeController = TextEditingController(text: property?.code ?? '');
  final locationController = TextEditingController(text: property?.location ?? '');
  final descriptionController = TextEditingController(
    text: property?.description ?? '',
  );
  final floorsController = TextEditingController(
    text: '${property?.floorsCount ?? 1}',
  );
  var status = property?.status ?? PropertyStatus.active;
  final assignedUsers = {...?property?.assignedUserIds};

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(property == null ? 'add_property'.tr : 'edit_property'.tr),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                children: [
                  AppTextField(controller: nameController, label: 'property_name'.tr),
                  const SizedBox(height: 12),
                  AppTextField(controller: codeController, label: 'property_code'.tr),
                  const SizedBox(height: 12),
                  AppTextField(controller: locationController, label: 'location'.tr),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: descriptionController,
                    label: 'description'.tr,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: floorsController,
                    label: 'floors_count'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PropertyStatus>(
                    initialValue: status,
                    items: PropertyStatus.values
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workspace.users
                        .map(
                          (user) => FilterChip(
                            label: Text(user.fullName),
                            selected: assignedUsers.contains(user.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  assignedUsers.add(user.id);
                                } else {
                                  assignedUsers.remove(user.id);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
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
                await workspace.addOrUpdateProperty(
                  PropertyRecord(
                    id: property?.id ?? 'property_${DateTime.now().microsecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    code: codeController.text.trim(),
                    location: locationController.text.trim(),
                    description: descriptionController.text.trim(),
                    floorsCount: int.tryParse(floorsController.text.trim()) ?? 1,
                    unitsCount: property?.unitsCount ?? 0,
                    status: status,
                    assignedUserIds: assignedUsers.toList(),
                    attachments: property?.attachments ?? const [],
                    createdAt: property?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text('save'.tr),
            ),
          ],
        ),
      );
    },
  );
}
