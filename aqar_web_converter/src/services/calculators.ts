// Business domain calculators converted from aqarelmasryeen/lib/features/**/domain
import {
  Installment,
  InstallmentPlan,
  InstallmentStatus,
  Partner,
  PartnerSettlement,
  ExpenseRecord,
  PropertyProject,
  UnitSale,
} from '@/types';

export class InstallmentPlanGenerator {
  static generate(plan: InstallmentPlan, actorId = 'admin'): Installment[] {
    const list: Installment[] = [];
    const baseDate = new Date(plan.startDate);

    for (let i = 0; i < plan.installmentCount; i++) {
      const dueDate = new Date(baseDate.getTime() + i * plan.intervalDays * 24 * 60 * 60 * 1000);
      const isPast = dueDate.getTime() < Date.now();

      list.push({
        id: `inst-${plan.id}-${i + 1}`,
        planId: plan.id,
        propertyId: plan.propertyId,
        unitId: plan.unitId,
        sequence: i + 1,
        amount: plan.installmentAmount,
        paidAmount: 0,
        dueDate: dueDate.toISOString().split('T')[0],
        status: isPast ? InstallmentStatus.Overdue : InstallmentStatus.Pending,
        customerName: plan.customerName,
      });
    }

    return list;
  }
}

export class PartnerSettlementCalculator {
  static build(partners: Partner[], expenses: ExpenseRecord[]): PartnerSettlement[] {
    const totalExpenses = expenses.reduce((sum, item) => sum + item.amount, 0);

    return partners.map(partner => {
      const contributed = expenses
        .filter(exp => exp.paidByPartnerId === partner.id)
        .reduce((sum, item) => sum + item.amount, 0);

      const expected = totalExpenses * partner.shareRatio;
      const balanceDelta = contributed - expected;

      return {
        partnerId: partner.id,
        partnerName: partner.name,
        contributedAmount: contributed,
        shareRatio: partner.shareRatio,
        expectedContribution: expected,
        balanceDelta,
      };
    });
  }
}

export class PropertyFinancialSummary {
  static calculate(
    property: PropertyProject,
    units: UnitSale[],
    expenses: ExpenseRecord[],
    installments: Installment[]
  ) {
    const totalSoldUnits = units.filter(u => u.status === 'sold' && u.propertyId === property.id);
    const totalSalesValue = totalSoldUnits.reduce((acc, u) => acc + u.salePrice, 0);
    const totalDownPayments = totalSoldUnits.reduce((acc, u) => acc + u.downPayment, 0);

    const propInstallments = installments.filter(inst => inst.propertyId === property.id);
    const totalInstallmentPaid = propInstallments.reduce((acc, i) => acc + i.paidAmount, 0);
    const totalCollections = totalDownPayments + totalInstallmentPaid;

    const propExpenses = expenses.filter(e => e.propertyId === property.id);
    const totalExpenses = propExpenses.reduce((acc, e) => acc + e.amount, 0);

    const netProfit = totalCollections - totalExpenses;
    const collectionPercentage = totalSalesValue > 0 ? (totalCollections / totalSalesValue) * 100 : 0;

    return {
      totalSoldUnits: totalSoldUnits.length,
      remainingUnits: property.apartmentCount - totalSoldUnits.length,
      totalSalesValue,
      totalCollections,
      totalExpenses,
      netProfit,
      collectionPercentage: Math.round(collectionPercentage),
    };
  }
}
