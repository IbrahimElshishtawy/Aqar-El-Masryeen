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
    return NextResponse.json({ error: 'جلسة العمل غير صالحة أو منتهية' }, { status: 401 });
  }

  const metrics = accountingService.getPriceMetrics();
  const history = accountingService.getPriceHistory();

  return NextResponse.json({
    success: true,
    data: {
      metrics,
      history,
    },
  });
}

export async function POST(request: NextRequest) {
  const token = request.cookies.get(SessionService.cookieName)?.value;
  if (!token) {
    return NextResponse.json({ error: 'غير مصرح لك، يرجى تسجيل الدخول' }, { status: 401 });
  }

  const session = await SessionService.verifyToken(token);
  if (!session) {
    return NextResponse.json({ error: 'جلسة العمل منتهية الصلاحية' }, { status: 401 });
  }

  // Check RBAC permission for managing prices
  if (!SessionService.hasPermission(session.role, 'manage_price_monitoring')) {
    return NextResponse.json(
      { error: 'ليس لديك صلاحية لتعديل أسعار الوحدات أو المشروعات' },
      { status: 403 }
    );
  }

  try {
    const body = await request.json();
    const { unitId, newPrice, reason } = body;

    if (!unitId || typeof newPrice !== 'number' || newPrice <= 0) {
      return NextResponse.json(
        { error: 'معرف الوحدة والسعر الجديد مطلوبان وبقيمة موجبة' },
        { status: 400 }
      );
    }

    const priceRecord = accountingService.updateUnitPrice(session, unitId, newPrice, reason);

    return NextResponse.json({
      success: true,
      message: 'تم تحديث سعر الوحدة بنجاح وتوثيق العملية في سجل الأسعار التاريخي',
      record: priceRecord,
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error?.message || 'حدث خطأ أثناء تعديل السعر' },
      { status: 500 }
    );
  }
}
