import { PriceHistoryRecord, UnitSale, PropertyProject } from '@/types';
import { roundToTwoDecimals } from '../accounting/precision';

export interface PriceMetric {
  unitId: string;
  propertyId: string;
  propertyName: string;
  unitNumber: string;
  unitType: string;
  areaSqm: number;
  currentAskingPrice: number;
  pricePerMeter: number;
  previousPrice: number;
  absoluteChange: number;
  percentageChange: number;
  lastUpdated: string;
  status: string;
  history: PriceHistoryRecord[];
}

export class PriceMonitoringEngine {
  /**
   * Builds price metrics and historical comparison for units
   */
  static buildPriceMetrics(params: {
    projects: PropertyProject[];
    units: UnitSale[];
    historyRecords: PriceHistoryRecord[];
  }): PriceMetric[] {
    const { projects, units, historyRecords } = params;
    const projectMap = new Map(projects.map(p => [p.id, p]));

    return units.map(unit => {
      const project = projectMap.get(unit.propertyId);
      const propertyName = project?.name || 'مشروع غير محدد';
      const unitHistory = historyRecords
        .filter(h => h.unitId === unit.id)
        .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

      const latestRecord = unitHistory[0];
      const previousPrice = latestRecord ? latestRecord.previousPrice : unit.salePrice;
      const absoluteChange = roundToTwoDecimals(unit.salePrice - previousPrice);
      const percentageChange = previousPrice > 0
        ? roundToTwoDecimals(((unit.salePrice - previousPrice) / previousPrice) * 100)
        : 0;

      const pricePerMeter = unit.areaSqm > 0
        ? roundToTwoDecimals(unit.salePrice / unit.areaSqm)
        : 0;

      return {
        unitId: unit.id,
        propertyId: unit.propertyId,
        propertyName,
        unitNumber: unit.unitNumber,
        unitType: unit.unitType,
        areaSqm: unit.areaSqm,
        currentAskingPrice: unit.salePrice,
        pricePerMeter,
        previousPrice,
        absoluteChange,
        percentageChange,
        lastUpdated: latestRecord?.timestamp || unit.contractDate || '2026-04-01',
        status: unit.status,
        history: unitHistory,
      };
    });
  }

  /**
   * Generates a new PriceHistoryRecord when a price is updated
   */
  static createPriceChangeRecord(params: {
    unit: UnitSale;
    propertyName: string;
    newPrice: number;
    changedBy: string;
    changedByName: string;
    reason?: string;
  }): { record: PriceHistoryRecord; updatedUnit: UnitSale } {
    const { unit, propertyName, newPrice, changedBy, changedByName, reason } = params;
    const previousPrice = unit.salePrice;
    const absoluteChange = roundToTwoDecimals(newPrice - previousPrice);
    const percentageChange = previousPrice > 0
      ? roundToTwoDecimals(((newPrice - previousPrice) / previousPrice) * 100)
      : 0;

    const record: PriceHistoryRecord = {
      id: `price-hist-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      propertyId: unit.propertyId,
      unitId: unit.id,
      entityType: 'unit',
      propertyName,
      unitNumber: unit.unitNumber,
      previousPrice,
      newPrice,
      absoluteChange,
      percentageChange,
      reason: reason || 'تحديث دوري لأسعار السوق والتشطيبات',
      changedBy,
      changedByName,
      timestamp: new Date().toISOString(),
    };

    const updatedUnit: UnitSale = {
      ...unit,
      salePrice: newPrice,
    };

    return { record, updatedUnit };
  }
}
