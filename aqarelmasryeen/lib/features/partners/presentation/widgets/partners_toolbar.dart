part of '../partners_screen.dart';

class _PartnerToolbar extends StatelessWidget {
  const _PartnerToolbar({
    required this.searchController,
    required this.activeFilter,
    required this.pendingCount,
    required this.linkingAccount,
    required this.onCreatePartner,
    required this.onLinkAccount,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final _PartnersFilter activeFilter;
  final int pendingCount;
  final bool linkingAccount;
  final VoidCallback onCreatePartner;
  final VoidCallback onLinkAccount;
  final ValueChanged<_PartnersFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E9EE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCreatePartner,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إنشاء شريك'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: linkingAccount ? null : onLinkAccount,
                  icon: linkingAccount
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link_rounded),
                  label: Text(
                    linkingAccount
                        ? 'جارٍ تنفيذ الربط...'
                        : pendingCount > 0
                        ? 'ربط حساب ($pendingCount)'
                        : 'ربط حساب',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ابحث باسم الشريك أو البريد الإلكتروني',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF6F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: 8,
              children: [
                _FilterChipButton(
                  label: 'الكل',
                  selected: activeFilter == _PartnersFilter.all,
                  onTap: () => onFilterChanged(_PartnersFilter.all),
                ),
                _FilterChipButton(
                  label: 'له حساب',
                  selected: activeFilter == _PartnersFilter.hasAccount,
                  onTap: () => onFilterChanged(_PartnersFilter.hasAccount),
                ),
                _FilterChipButton(
                  label: 'بدون حساب',
                  selected: activeFilter == _PartnersFilter.noAccount,
                  onTap: () => onFilterChanged(_PartnersFilter.noAccount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
