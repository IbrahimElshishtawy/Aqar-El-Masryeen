import 'package:aqarelmasryeen/core/widgets/app_form_sheet.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_ledger_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PartnerLedgerEntryFormSheet extends ConsumerStatefulWidget {
  const PartnerLedgerEntryFormSheet({
    super.key,
    required this.partner,
    this.entry,
  });

  final Partner partner;
  final PartnerLedgerEntry? entry;

  @override
  ConsumerState<PartnerLedgerEntryFormSheet> createState() =>
      _PartnerLedgerEntryFormSheetState();
}

class _PartnerLedgerEntryFormSheetState
    extends ConsumerState<PartnerLedgerEntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late PartnerLedgerEntryType _entryType;
  bool _authorized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.entry == null ? '' : widget.entry!.amount.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
    _entryType = widget.entry?.entryType ?? PartnerLedgerEntryType.contribution;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_authorized) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() => _saving = true);

    final entry = PartnerLedgerEntry(
      id: widget.entry?.id ?? '',
      partnerId: widget.partner.id,
      propertyId: widget.entry?.propertyId ?? '',
      entryType: _entryType,
      amount: double.parse(_amountController.text.trim()),
      notes: _notesController.text.trim(),
      authorizedBy: session.userId,
      createdBy: widget.entry?.createdBy ?? session.userId,
      updatedBy: session.userId,
      createdAt:
          widget.entry?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.now(),
      archived: false,
    );

    final savedId = await ref
        .read(partnerLedgerRepositoryProvider)
        .saveAuthorized(entry);
    await ref
        .read(activityRepositoryProvider)
        .log(
          actorId: session.userId,
          actorName: session.profile?.name ?? 'Partner',
          action: widget.entry == null
              ? 'partner_ledger_created'
              : 'partner_ledger_updated',
          entityType: 'partner_ledger',
          entityId: savedId,
          metadata: {'partnerId': widget.partner.id, 'amount': entry.amount},
        );
    await ref
        .read(notificationRepositoryProvider)
        .create(
          userId: session.userId,
          title: 'Important ledger update',
          body: '${widget.partner.name} ledger updated',
          type: NotificationType.ledgerUpdated,
          route: '/expenses',
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: 'Authorized Partner Entry',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              'Protected flow for ${widget.partner.name}. Enable authorization before saving.',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PartnerLedgerEntryType>(
              initialValue: _entryType,
              items: PartnerLedgerEntryType.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _entryType = value ?? _entryType),
              decoration: const InputDecoration(labelText: 'Entry type'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (value) {
                if ((double.tryParse((value ?? '').trim()) ?? 0) <= 0) {
                  return 'Enter a valid amount.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _authorized,
              title: const Text(
                'I confirm this is an authorized ledger action',
              ),
              onChanged: (value) => setState(() => _authorized = value),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Saving...' : 'Save authorized entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
