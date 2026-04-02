import 'package:aqarelmasryeen/features\auth\presentation\auth_providers.dart';
import 'package:aqarelmasryeen/features\properties\data\property_repository.dart';
import 'package:aqarelmasryeen/shared\enums\app_enums.dart';
import 'package:aqarelmasryeen/shared\models\property_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({super.key});

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _salesTargetController = TextEditingController();
  PropertyStatus _status = PropertyStatus.active;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _salesTargetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final user = ref.read(authSessionProvider).value?.firebaseUser;
    if (user == null) return;

    final property = PropertyProject(
      id: '',
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      totalBudget: double.tryParse(_budgetController.text) ?? 0,
      totalSalesTarget: double.tryParse(_salesTargetController.text) ?? 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: user.uid,
      updatedBy: user.uid,
      archived: false,
    );

    await ref.read(propertyRepositoryProvider).save(property);
    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add property')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Project name')),
              const SizedBox(height: 14),
              TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
              const SizedBox(height: 14),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<PropertyStatus>(
                value: _status,
                items: PropertyStatus.values
                    .map((status) => DropdownMenuItem(value: status, child: Text(status.name)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value ?? PropertyStatus.active),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Budget'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _salesTargetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sales target'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Create property'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
