import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/async_value_view.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features\properties\data\property_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({
    super.key,
    this.propertyId,
  });

  final String? propertyId;

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _salesTargetController = TextEditingController();
  PropertyStatus _status = PropertyStatus.active;
  bool _saving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _salesTargetController.dispose();
    super.dispose();
  }

  void _hydrate(PropertyProject property) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = property.name;
    _locationController.text = property.location;
    _descriptionController.text = property.description;
    _budgetController.text = property.totalBudget.toStringAsFixed(0);
    _salesTargetController.text = property.totalSalesTarget.toStringAsFixed(0);
    _status = property.status;
  }

  Future<void> _save(PropertyProject? existing) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final user = ref.read(authSessionProvider).value?.firebaseUser;
    if (user == null) return;

    final property = PropertyProject(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      totalBudget: double.tryParse(_budgetController.text) ?? 0,
      totalSalesTarget: double.tryParse(_salesTargetController.text) ?? 0,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: existing?.createdBy ?? user.uid,
      updatedBy: user.uid,
      archived: false,
    );

    final propertyId = await ref.read(propertyRepositoryProvider).save(property);
    await ref.read(activityRepositoryProvider).log(
      actorId: user.uid,
      actorName: ref.read(authSessionProvider).value?.profile?.name ?? 'Partner',
      action: existing == null ? 'property_created' : 'property_updated',
      entityType: 'property',
      entityId: propertyId,
      metadata: {
        'name': property.name,
        'status': property.status.name,
      },
    );
    if (mounted) {
      setState(() => _saving = false);
      context.go(AppRoutes.propertyDetails(propertyId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = widget.propertyId == null
        ? const AsyncData<PropertyProject?>(null)
        : ref.watch(
            StreamProvider.autoDispose<PropertyProject?>(
              (ref) => ref.watch(propertyRepositoryProvider).watchProperty(widget.propertyId!),
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propertyId == null ? 'Add property' : 'Edit property'),
      ),
      body: SafeArea(
        child: AsyncValueView<PropertyProject?>(
          value: propertyAsync,
          data: (existing) {
            if (existing != null) {
              _hydrate(existing);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Project name'),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Enter the property name.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'Location'),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Enter the project location.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Description'),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<PropertyStatus>(
                          value: _status,
                          items: PropertyStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _status = value ?? PropertyStatus.active),
                          decoration: const InputDecoration(labelText: 'Status'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _budgetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Budget'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _salesTargetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Sales target'),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : () => _save(existing),
                            child: Text(
                              _saving
                                  ? 'Saving...'
                                  : widget.propertyId == null
                                      ? 'Create property'
                                      : 'Save changes',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
