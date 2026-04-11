part of '../partners_screen.dart';

class _PartnerAccountsSection extends StatelessWidget {
  const _PartnerAccountsSection({
    required this.accountsAsync,
    required this.accounts,
    required this.activeFilter,
    required this.currentWorkspaceId,
    required this.totalAccountsCount,
    required this.createdByMeCount,
    required this.linkedCount,
    required this.availableLinkCount,
    required this.onFilterChanged,
    required this.onLinkToCurrentContext,
    required this.onRetry,
  });

  final AsyncValue<List<PartnerAccountSummary>> accountsAsync;
  final List<PartnerAccountSummary> accounts;
  final _PartnerAccountsFilter activeFilter;
  final String currentWorkspaceId;
  final int totalAccountsCount;
  final int createdByMeCount;
  final int linkedCount;
  final int availableLinkCount;
  final ValueChanged<_PartnerAccountsFilter> onFilterChanged;
  final Future<void> Function(PartnerAccountSummary summary)
  onLinkToCurrentContext;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E9EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الحسابات داخل النظام',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'عرض المستخدمين الذين لديهم حسابات فعلية أو تم إنشاؤهم وربطهم بالنظام.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagPill(
                icon: Icons.people_alt_outlined,
                label: 'كل الحسابات: $totalAccountsCount',
              ),
              _TagPill(
                icon: Icons.person_add_alt_rounded,
                label: 'أنشأتها أنا: $createdByMeCount',
              ),
              _TagPill(
                icon: Icons.link_rounded,
                label: 'المرتبطة: $linkedCount',
              ),
              _TagPill(
                icon: Icons.person_search_rounded,
                label: 'المتاحة للربط: $availableLinkCount',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipButton(
                label: 'كل المستخدمين',
                selected: activeFilter == _PartnerAccountsFilter.all,
                onTap: () => onFilterChanged(_PartnerAccountsFilter.all),
              ),
              _FilterChipButton(
                label: 'تم إنشاؤهم بواسطتي',
                selected: activeFilter == _PartnerAccountsFilter.createdByMe,
                onTap: () =>
                    onFilterChanged(_PartnerAccountsFilter.createdByMe),
              ),
              _FilterChipButton(
                label: 'المرتبطون فقط',
                selected: activeFilter == _PartnerAccountsFilter.linkedOnly,
                onTap: () => onFilterChanged(_PartnerAccountsFilter.linkedOnly),
              ),
              _FilterChipButton(
                label: 'غير المرتبطين',
                selected: activeFilter == _PartnerAccountsFilter.unlinked,
                onTap: () => onFilterChanged(_PartnerAccountsFilter.unlinked),
              ),
              _FilterChipButton(
                label: 'ضمن نفس مساحة العمل',
                selected: activeFilter == _PartnerAccountsFilter.sameWorkspace,
                onTap: () =>
                    onFilterChanged(_PartnerAccountsFilter.sameWorkspace),
              ),
              _FilterChipButton(
                label: 'الذين لهم حساب',
                selected:
                    activeFilter == _PartnerAccountsFilter.hasLoginAccount,
                onTap: () =>
                    onFilterChanged(_PartnerAccountsFilter.hasLoginAccount),
              ),
              _FilterChipButton(
                label: 'المتاحون للربط',
                selected:
                    activeFilter == _PartnerAccountsFilter.availableForLink,
                onTap: () =>
                    onFilterChanged(_PartnerAccountsFilter.availableForLink),
              ),
            ],
          ),
          const SizedBox(height: 12),
          accountsAsync.when(
            data: (_) {
              if (totalAccountsCount == 0) {
                return const EmptyStateView(
                  title: 'لا توجد حسابات مسجلة داخل النظام',
                  message:
                      'تأكد من إنشاء profile للمستخدمين داخل مجموعة users.',
                );
              }
              if (accounts.isEmpty) {
                return const EmptyStateView(
                  title: 'لا توجد حسابات متاحة للربط',
                  message: 'جرّب تغيير فلتر الحسابات أو تعديل عبارة البحث.',
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < accounts.length; index++) ...[
                    _PartnerAccountCard(
                      summary: accounts[index],
                      currentWorkspaceId: currentWorkspaceId,
                      onLinkToCurrentContext: onLinkToCurrentContext,
                    ),
                    if (index != accounts.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              );
            },
            error: (error, _) => LoadFailureView(
              title: 'تعذر تحميل حسابات المستخدمين',
              error: error,
              onRetry: onRetry,
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerAccountCard extends StatefulWidget {
  const _PartnerAccountCard({
    required this.summary,
    required this.currentWorkspaceId,
    required this.onLinkToCurrentContext,
  });

  final PartnerAccountSummary summary;
  final String currentWorkspaceId;
  final Future<void> Function(PartnerAccountSummary summary)
  onLinkToCurrentContext;

  @override
  State<_PartnerAccountCard> createState() => _PartnerAccountCardState();
}

class _PartnerAccountCardState extends State<_PartnerAccountCard> {
  bool _linking = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.summary;
    final user = summary.user;
    final sameWorkspace =
        widget.currentWorkspaceId.isNotEmpty &&
        user.workspaceId.trim() == widget.currentWorkspaceId;
    final linkedPartnerName =
        summary.linkedPartner?.name.trim().isNotEmpty == true
        ? summary.linkedPartner!.name.trim()
        : user.linkedPartnerName.trim();
    final isAlreadyLinked = summary.isLinked && sameWorkspace;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE8ECF5),
                child: Text(
                  user.fullName.trim().isEmpty ? '?' : user.fullName.trim()[0],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.trim().isEmpty
                          ? 'مستخدم بدون اسم'
                          : user.fullName.trim(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.trim().isEmpty
                          ? 'لا يوجد بريد إلكتروني'
                          : user.email.trim(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _TagPill(
                icon: Icons.verified_user_outlined,
                label: 'لديه حساب',
              ),
              _TagPill(
                icon: summary.createdByCurrentUser
                    ? Icons.person_add_alt_1_rounded
                    : Icons.badge_outlined,
                label: summary.createdByCurrentUser
                    ? 'تم إنشاؤه بواسطتي'
                    : 'أنشأه ${summary.createdByName}',
              ),
              _TagPill(
                icon: summary.isLinked
                    ? Icons.link_rounded
                    : Icons.link_off_rounded,
                label: summary.isLinked
                    ? 'مرتبط: ${linkedPartnerName.isEmpty ? 'نعم' : linkedPartnerName}'
                    : 'بدون ربط',
              ),
              _TagPill(
                icon: sameWorkspace
                    ? Icons.check_circle_outline_rounded
                    : Icons.travel_explore_rounded,
                label: sameWorkspace
                    ? 'ضمن مساحة العمل الحالية'
                    : 'خارج مساحة العمل الحالية',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _InfoText(
                label: 'تاريخ الإنشاء',
                value: user.createdAt.formatShort(),
              ),
              _InfoText(label: 'UID مختصر', value: _shortUid(user.uid)),
              _InfoText(
                label: 'مساحة العمل',
                value: user.workspaceId.trim().isEmpty
                    ? 'غير محدد'
                    : user.workspaceId.trim(),
              ),
              _InfoText(
                label: 'الشريك المرتبط',
                value: linkedPartnerName.isEmpty
                    ? 'غير مرتبط'
                    : linkedPartnerName,
              ),
              _InfoText(
                label: 'حالة الحساب',
                value: user.isActive ? 'نشط' : 'معطل',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: isAlreadyLinked || _linking
                  ? null
                  : () async {
                      setState(() => _linking = true);
                      try {
                        await widget.onLinkToCurrentContext(summary);
                      } finally {
                        if (mounted) {
                          setState(() => _linking = false);
                        }
                      }
                    },
              icon: Icon(isAlreadyLinked ? Icons.check_circle : Icons.link),
              label: Text(
                isAlreadyLinked
                    ? 'مربوط بالحساب الحالي'
                    : _linking
                    ? 'جارٍ تنفيذ الربط...'
                    : 'ربط بهذا الحساب',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFF59607A)),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
