part of '../partner_form_sheet.dart';

String _resolveSessionEmail(AppSession? session) {
  final profileEmail = session?.profile?.email.trim().toLowerCase() ?? '';
  if (profileEmail.isNotEmpty) {
    return profileEmail;
  }
  return session?.email?.trim().toLowerCase() ?? '';
}

String _resolveWorkspaceId(AppSession? session) {
  final workspaceId = session?.profile?.workspaceId.trim() ?? '';
  return workspaceId;
}
