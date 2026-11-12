typedef BatteryVoltageRange = ({int minMv, int maxMv});

typedef BatteryCellReading = ({
  int cellCount,
  int averageCellMillivolts,
  int percent,
});

BatteryVoltageRange batteryVoltageRange(String chemistry) {
  switch (chemistry) {
    case 'lifepo4':
      return (minMv: 2600, maxMv: 3650);
    case 'lipo':
      return (minMv: 3000, maxMv: 4200);
    case 'lipo_hv':
      return (minMv: 3000, maxMv: 4350);
    case 'nmc':
    default:
      return (minMv: 3000, maxMv: 4200);
  }
}

int nominalCellMillivolts(String chemistry) {
  switch (chemistry) {
    case 'lifepo4':
      return 3200;
    case 'lipo_hv':
      return 3800;
    case 'lipo':
      return 3700;
    case 'nmc':
    default:
      return 3600;
  }
}

/// Number of series cells a reported pack voltage implies for [chemistry].
/// A voltage at or below the nominal cell voltage is a single cell; above it,
/// the count is the nearest cell multiple, biased so a full pack never
/// rounds up into the next cell count.
int batteryCellCount(int millivolts, String chemistry) {
  final nominal = nominalCellMillivolts(chemistry);
  if (millivolts <= nominal) return 1;
  final range = batteryVoltageRange(chemistry);
  final byNominal = (millivolts / nominal).round();
  final byMax = (millivolts / range.maxMv).ceil();
  final count = byNominal < byMax ? byNominal : byMax;
  return count < 1 ? 1 : count;
}

/// Reads a pack voltage as [cellCount] series cells: the average cell
/// voltage and the remaining capacity percent for that cell count.
BatteryCellReading batteryReadingFromMillivolts(
  int millivolts,
  String chemistry,
) {
  final cellCount = batteryCellCount(millivolts, chemistry);
  final averageCellMillivolts = (millivolts / cellCount).round();
  return (
    cellCount: cellCount,
    averageCellMillivolts: averageCellMillivolts,
    percent: estimateCellPercentFromMillivolts(
      averageCellMillivolts,
      chemistry,
    ),
  );
}

int estimateCellPercentFromMillivolts(int cellMillivolts, String chemistry) {
  final range = batteryVoltageRange(chemistry);
  if (cellMillivolts <= range.minMv) return 0;
  if (cellMillivolts >= range.maxMv) return 100;
  return (((cellMillivolts - range.minMv) * 100) / (range.maxMv - range.minMv))
      .round();
}

int estimateBatteryPercentFromMillivolts(int millivolts, String chemistry) {
  return batteryReadingFromMillivolts(millivolts, chemistry).percent;
}

int estimateBatteryPercentFromVolts(double volts, String chemistry) {
  final millivolts = (volts * 1000).round();
  return estimateBatteryPercentFromMillivolts(millivolts, chemistry);
}
