import { NextRequest, NextResponse } from 'next/server';
import { SessionService } from '@/lib/auth/session';
import { accountingService } from '@/services/accounting-service';

export async function GET(request: NextRequest) {
  const token = request.cookies.get(SessionService.cookieName)?.value;
  if (!token) {
    return NextResponse.json({ error: 'غير مصرح لك، يرجى تسجيل الدخول' }, { status: 401 });
  }

  const session = await SessionService.verifyToken(token);
  if (!session) {
    return NextResponse.json({ error: 'جلسة العمل منتهية الصلاحية' }, { status: 401 });
  }

  const reconciliation = accountingService.getReconciliation(session);

  // If role is partner, scope partner ledger to only this partner
  if (session.role === 'partner' && session.partnerId) {
    reconciliation.partnerLedgerRows = reconciliation.partnerLedgerRows.filter(
      row => row.partner.id === session.partnerId
    );
    reconciliation.settlements = reconciliation.settlements.filter(
      s => s.partnerId === session.partnerId
    );
  }

  return NextResponse.json({
    success: true,
    data: reconciliation,
    userRole: session.role,
  });
}
