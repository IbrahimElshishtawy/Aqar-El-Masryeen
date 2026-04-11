import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_top_bar.dart';
import 'package:aqarelmasryeen/core/widgets/async_value_view.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/presentation/properties_providers.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({super.key, this.propertyId});

  final String? propertyId;

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _apartmentCountController = TextEditingController();
  final _descriptionController = TextEditingController();
  PropertyStatus _status = PropertyStatus.planning;
  bool _saving = false;
  bool _prefilled = false;

  List<PropertyStatus> get _availableStatuses {
    final statuses = <PropertyStatus>[
      PropertyStatus.planning,
      PropertyStatus.delivered,
    ];
    if (!statuses.contains(_status) && _status != PropertyStatus.archived) {
      statuses.add(_status);
    }
    return statuses;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _apartmentCountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _hydrate(PropertyProject property) {
    if (_prefilled) {
      return;
    }
    _prefilled = true;
    _nameController.text = property.name;
    _locationController.text = property.location;
    _apartmentCountController.text = property.apartmentCount > 0
        ? property.apartmentCount.toString()
        : '';
    _descriptionController.text = property.description;
    _status = property.status;
  }

  Future<void> _save(PropertyProject? existing) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final session = ref.read(authSessionProvider).value;
    if (session == null) {
      if (mounted) {
        setState(() => _saving = false);
      }
      return;
    }

    final property = PropertyProject(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      apartmentCount: int.tryParse(_apartmentCountController.text.trim()) ?? 0,
      description: _descriptionController.text.trim(),
      status: _status,
      totalBudget: existing?.totalBudget ?? 0,
      totalSalesTarget: existing?.totalSalesTarget ?? 0,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: existing?.createdBy ?? session.userId,
      updatedBy: session.userId,
      workspaceId:
          existing?.workspaceId ?? ref.read(currentWorkspaceIdProvider),
      archived: existing?.archived ?? false,
    );
    try {
      final propertyId = await ref
          .read(propertyRepositoryProvider)
          .save(property);
      await ref
          .read(activityRepositoryProvider)
          .log(
            actorId: session.userId,
            actorName:
                ref.read(authSessionProvider).value?.profile?.name ?? 'شريك',
            action: existing == null ? 'property_created' : 'property_updated',
            entityType: 'property',
            entityId: propertyId,
            metadata: {
              'name': property.name,
              'location': property.location,
              'apartmentCount': property.apartmentCount,
              'status': property.status.label,
              'workspaceId': property.workspaceId,
            },
            workspaceId: property.workspaceId,
          );
      ref.invalidate(propertiesStreamProvider);
      ref.invalidate(propertiesViewDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null
                  ? 'تم إنشاء المشروع بنجاح'
                  : 'تم حفظ المشروع وتحديث الصفحة',
            ),
          ),
        );
        setState(() => _saving = false);
        context.go(AppRoutes.propertyDetails(propertyId));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر حفظ المشروع')));
        setState(() => _saving = false);
      }
    }
  }

  String? _validateApartmentCount(String? value) {
    final count = int.tryParse((value ?? '').trim());
    if (count == null || count <= 0) {
      return 'أدخل عدد الشقق داخل العقار.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = widget.propertyId == null
        ? const AsyncData<PropertyProject?>(null)
        : ref.watch(
            StreamProvider.autoDispose<PropertyProject?>((ref) {
              return ref
                  .watch(propertyRepositoryProvider)
                  .watchProperty(
                    widget.propertyId!,
                    workspaceId: ref.watch(currentWorkspaceIdProvider),
                  );
            }),
          );

    return Scaffold(
      appBar: AppTopBar(
        title: widget.propertyId == null ? 'إضافة عقار' : 'تعديل بيانات العقار',
        subtitle: 'الاسم والموقع وعدد الشقق وحالة التنفيذ والوصف',
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
                          decoration: const InputDecoration(
                            labelText: 'اسم العقار',
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'أدخل اسم العقار.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'الموقع',
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'أدخل موقع العقار.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _apartmentCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'عدد الشقق',
                          ),
                          validator: _validateApartmentCount,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<PropertyStatus>(
                          initialValue: _status,
                          items: _availableStatuses
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(
                            () => _status = value ?? PropertyStatus.planning,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'الحالة',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'الوصف',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : () => _save(existing),
                            child: Text(
                              _saving
                                  ? 'جار الحفظ...'
                                  : widget.propertyId == null
                                  ? 'إنشاء العقار'
                                  : 'حفظ التعديلات',
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
