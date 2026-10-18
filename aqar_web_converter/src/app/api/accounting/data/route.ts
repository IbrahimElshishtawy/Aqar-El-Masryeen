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

  const projects = accountingService.getProjects();
  const units = accountingService.getUnits(session);
  const installments = accountingService.getInstallments(session);
  const expenses = accountingService.getExpenses(session);
  const materialExpenses = accountingService.getMaterialExpenses();
  const supplierPayments = accountingService.getSupplierPayments();
  const partners = accountingService.getPartners(session);
  const partnerLedgers = accountingService.getPartnerLedgers(session);
  const payments = accountingService.getPayments();
  const activityLogs = accountingService.getActivityLogs(session);
  const reconciliation = accountingService.getReconciliation(session);

  return NextResponse.json({
    success: true,
    user: {
      uid: session.uid,
      email: session.email,
      fullName: session.fullName,
      role: session.role,
      partnerId: session.partnerId,
    },
    data: {
      projects,
      units,
      installments,
      expenses,
      materialExpenses,
      supplierPayments,
      partners,
      partnerLedgers,
      payments,
      activityLogs,
      reconciliation,
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

  try {
    const body = await request.json();
    const { action, payload } = body;

    switch (action) {
      case 'create_expense': {
        if (!SessionService.hasPermission(session.role, 'manage_expenses')) {
          return NextResponse.json({ error: 'ليس لديك صلاحية لإضافة مصروفات' }, { status: 403 });
        }
        const created = accountingService.recordExpense(session, payload);
        return NextResponse.json({ success: true, item: created });
      }

      case 'create_material_expense': {
        if (!SessionService.hasPermission(session.role, 'manage_expenses')) {
          return NextResponse.json({ error: 'ليس لديك صلاحية لتسجيل تشوينات ومواد بناء' }, { status: 403 });
        }
        const created = accountingService.recordMaterialExpense(session, payload);
        return NextResponse.json({ success: true, item: created });
      }

      case 'record_supplier_payment': {
        if (!SessionService.hasPermission(session.role, 'manage_expenses')) {
          return NextResponse.json({ error: 'ليس لديك صلاحية لسداد دفعات للموردين' }, { status: 403 });
        }
        const created = accountingService.recordSupplierPayment(session, payload);
        return NextResponse.json({ success: true, item: created });
      }

      case 'create_partner_ledger_entry': {
        if (!SessionService.hasPermission(session.role, 'manage_partners')) {
          return NextResponse.json({ error: 'فقط الأدمن يمكنه إضافة قيود في دفاتر الشركاء' }, { status: 403 });
        }
        const created = accountingService.recordPartnerLedgerEntry(session, payload);
        return NextResponse.json({ success: true, item: created });
      }

      case 'record_customer_payment': {
        if (!SessionService.hasPermission(session.role, 'manage_installments')) {
          return NextResponse.json({ error: 'ليس لديك صلاحية لتسجيل دفعات العملاء' }, { status: 403 });
        }
        const created = accountingService.recordPayment(session, payload);
        return NextResponse.json({ success: true, item: created });
      }

      case 'create_project': {
        if (session.role !== 'admin') {
          return NextResponse.json({ error: 'فقط مدير المنظومة (Admin) يمكنه إنشاء مشروعات جديدة' }, { status: 403 });
        }
        const created = accountingService.createProject(session, payload);
        return NextResponse.json({ success: true, item: created });
      }

      case 'create_unit': {
        if (session.role !== 'admin' && session.role !== 'accountant') {
          return NextResponse.json({ error: 'غير مصرح لك بإضافة وحدات للمشروع' }, { status: 403 });
        }
        const created = accountingService.createUnit(session, payload);
        return NextResponse.json({ success: true, item: created });
      }

      case 'create_partner': {
        if (session.role !== 'admin') {
          return NextResponse.json({ error: 'فقط مدير المنظومة يمكنه تسجيل شركاء جدد' }, { status: 403 });
        }
        const created = accountingService.createPartner(session, payload);
        return NextResponse.json({ success: true, item: created });
      }

      default:
        return NextResponse.json({ error: `إجراء غير معروف: ${action}` }, { status: 400 });
    }
  } catch (error: any) {
    return NextResponse.json(
      { error: error?.message || 'حدث خطأ أثناء تنفيذ المعاملة' },
      { status: 500 }
    );
  }
}
