import 'package:aqarelmasryeen/core/responsive/app_breakpoints.dart';
import 'package:aqarelmasryeen/core/theme/app_colors.dart';
import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/data/models/app_role.dart';
import 'package:aqarelmasryeen/data/models/user_profile.dart';
import 'package:aqarelmasryeen/data/repositories/workspace_repository.dart';
import 'package:aqarelmasryeen/modules/dashboard/widgets/workspace_ui.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_card.dart';
import 'package:aqarelmasryeen/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UsersSection extends StatefulWidget {
  const UsersSection({super.key});

  @override
  State<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  final workspace = Get.find<WorkspaceRepository>();
  final searchController = TextEditingController();
  AppRole? roleFilter;

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final items = workspace.users.where((user) {
      final matchesQuery =
          user.fullName.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query);
      final matchesRole = roleFilter == null || user.role == roleFilter;
      return matchesQuery && matchesRole;
    }).toList();

    return SectionScaffold(
      title: 'workers'.tr,
      subtitle: 'users_subtitle'.tr,
      action: workspace.canManageUsers
          ? SizedBox(
              width: 160,
              child: AppButton(
                label: 'add_worker'.tr,
                onPressed: () => _showUserDialog(context),
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
                  width: 320,
                  child: AppTextField(
                    controller: searchController,
                    label: 'search'.tr,
                    prefixIcon: const Icon(Icons.search_rounded),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<AppRole?>(
                    value: roleFilter,
                    items: [
                      DropdownMenuItem<AppRole?>(
                        value: null,
                        child: Text('all_roles'.tr),
                      ),
                      ...AppRole.values.map(
                        (role) => DropdownMenuItem<AppRole?>(
                          value: role,
                          child: Text(role.labelKey.tr),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => roleFilter = value),
                    decoration: InputDecoration(labelText: 'role'.tr),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: AppButton(
                    label: 'apply'.tr,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (items.isEmpty)
            EmptyStateCard(
              title: 'empty_users'.tr,
              body: 'empty_users_body'.tr,
              actionLabel: workspace.canManageUsers ? 'add_worker'.tr : null,
              onPressed: workspace.canManageUsers
                  ? () => _showUserDialog(context)
                  : null,
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: items
                  .map(
                    (user) => SizedBox(
                      width: context.isDesktop ? 360 : double.infinity,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.fullName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(user.role.labelKey.tr),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(user.phone),
                            if (user.email != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                user.email!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: user.assignedProperties
                                  .map(
                                    (id) => Chip(
                                      label: Text(workspace.propertyNameById(id)),
                                      side: const BorderSide(color: AppColors.border),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: 'edit'.tr,
                                variant: AppButtonVariant.secondary,
                                onPressed: workspace.canManageUsers
                                    ? () => _showUserDialog(context, user: user)
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
        ],
      ),
    );
  }

  Future<void> _showUserDialog(BuildContext context, {UserProfile? user}) async {
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final notesController = TextEditingController(text: user?.notes ?? '');
    var selectedRole = user?.role ?? AppRole.employee;
    final selectedProperties = {...?user?.assignedProperties};
    var isActive = user?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(user == null ? 'add_worker'.tr : 'edit_worker'.tr),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 520,
                child: Column(
                  children: [
                    AppTextField(controller: nameController, label: 'full_name'.tr),
                    const SizedBox(height: 12),
                    AppTextField(controller: phoneController, label: 'phone_number'.tr),
                    const SizedBox(height: 12),
                    AppTextField(controller: emailController, label: 'email_optional'.tr),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AppRole>(
                      value: selectedRole,
                      items: AppRole.values
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.labelKey.tr),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => selectedRole = value!),
                      decoration: InputDecoration(labelText: 'role'.tr),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: workspace.properties
                          .map(
                            (property) => FilterChip(
                              label: Text(property.name),
                              selected: selectedProperties.contains(property.id),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedProperties.add(property.id);
                                  } else {
                                    selectedProperties.remove(property.id);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value),
                      title: Text('active_status'.tr),
                    ),
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
                  await workspace.addOrUpdateUser(
                    UserProfile(
                      id: user?.id ?? 'user_${DateTime.now().microsecondsSinceEpoch}',
                      fullName: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      role: selectedRole,
                      assignedProperties: selectedProperties.toList(),
                      isActive: isActive,
                      notes: notesController.text.trim(),
                      createdAt: user?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  if (mounted) {
                    setState(() {});
                  }
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
