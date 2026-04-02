import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PartnerFormSheet extends ConsumerStatefulWidget {
  const PartnerFormSheet({
    super.key,
    this.partner,
  });

  final Partner? partner;

  @override
  ConsumerState<PartnerFormSheet> createState() => _PartnerFormSheetState();
}

class _PartnerFormSheetState extends ConsumerState<PartnerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shareController;
  late final TextEditingController _contributionController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.partner?.name ?? '');
    _shareController = TextEditingController(
      text: widget.partner == null
          ? '50'
          : (widget.partner!.shareRatio * 100).toStringAsFixed(0),
    );
    _contributionController = TextEditingController(
      text: widget.partner == null
          ? '0'
          : widget.partner!.contributionTotal.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shareController.dispose();
    _contributionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final partner = Partner(
      id: widget.partner?.id ?? '',
      userId: widget.partner?.userId ?? '',
      name: _nameController.text.trim(),
      shareRatio: (double.tryParse(_shareController.text.trim()) ?? 0) / 100,
      contributionTotal: double.tryParse(_contributionController.text.trim()) ?? 0,
      createdAt: widget.partner?.createdAt ?? now,
      updatedAt: now,
    );

    final partnerId = await ref.read(partnerRepositoryProvider).upsert(partner);
    await ref.read(activityRepositoryProvider).log(
      actorId: session.firebaseUser.uid,
      actorName: session.profile?.name ?? 'Partner',
      action: widget.partner == null ? 'partner_created' : 'partner_updated',
      entityType: 'partner',
      entityId: partnerId,
      metadata: {
        'shareRatio': partner.shareRatio,
        'contributionTotal': partner.contributionTotal,
      },
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.partner == null ? 'Add partner record' : 'Edit partner',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Partner name'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a partner name.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shareController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Share ratio %'),
              validator: (value) {
                final share = double.tryParse((value ?? '').trim()) ?? -1;
                if (share <= 0 || share > 100) {
                  return 'Enter a value between 0 and 100.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contributionController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Capital contributions'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Saving...' : 'Save partner'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
