// ignore_for_file: invalid_use_of_protected_member

part of '../partner_form_sheet.dart';

extension _PartnerFormSheetFields on _PartnerFormSheetState {
  Widget _buildFormFields(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'اسم الشريك'),
          validator: AuthValidators.name,
        ),
        if (_canCreateLinkedAccount) ...[
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _createPartnerAccount,
            onChanged: _linkToCurrentAccount
                ? null
                : (value) => setState(() {
                    _createPartnerAccount = value;
                    if (value) {
                      _linkToCurrentAccount = false;
                    }
                  }),
            title: const Text('إنشاء حساب دخول للشريك'),
            subtitle: const Text(
              'اكتب اسم الشريك وإيميله وكلمة المرور، وبعد أول تسجيل دخول هيظهر له نفس المشروعات والحسابات.',
            ),
          ),
        ],
        if (_createPartnerAccount) ...[
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: true,
            onChanged: null,
            title: const Text('ربط الحساب تلقائيًا بمساحة عملي'),
            subtitle: const Text(
              'عند التفعيل سيتم تعيين مساحة العمل وربط الحساب فور إنشائه بدون خطوات إضافية.',
            ),
          ),
        ],
        const SizedBox(height: 4),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _linkToCurrentAccount,
          onChanged: _createPartnerAccount
              ? null
              : (value) => setState(() {
                  _linkToCurrentAccount = value;
                  if (value) {
                    final session = ref.read(authSessionProvider).valueOrNull;
                    _emailController.text = _resolveSessionEmail(session);
                  }
                }),
          title: const Text('ربط بالحساب الحالي مباشرة'),
          subtitle: const Text(
            'استخدمه فقط لو هذا الشريك هو نفس الحساب المفتوح الآن.',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          enabled: !_linkToCurrentAccount,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'إيميل تسجيل الدخول',
            helperText: _createPartnerAccount
                ? 'هذا الإيميل وكلمة المرور هما بيانات دخول الشريك.'
                : 'اكتب إيميل حساب موجود لربطه بالشريك أو لإرسال طلب ربط.',
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          validator: (value) {
            final text = (value ?? '').trim();
            if (_linkToCurrentAccount) {
              return null;
            }
            if (text.isEmpty) {
              return _createPartnerAccount
                  ? 'أدخل بريد الشريك لإنشاء الحساب.'
                  : null;
            }
            return AuthValidators.email(text);
          },
        ),
        if (_createPartnerAccount) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: AuthValidators.password,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) =>
                AuthValidators.confirmPassword(value, _passwordController.text),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(_savingButtonLabel),
                    ],
                  )
                : Text(_submitButtonLabel),
          ),
        ),
      ],
    );
  }
}
