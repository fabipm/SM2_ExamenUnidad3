enum ReportPeriod {
  monthly,
  quarterly,
  semiannual,
  annual,
}

extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.monthly:
        return 'Mensual';
      case ReportPeriod.quarterly:
        return 'Trimestral';
      case ReportPeriod.semiannual:
        return 'Semestral';
      case ReportPeriod.annual:
        return 'Anual';
    }
  }

  int get monthsCount {
    switch (this) {
      case ReportPeriod.monthly:
        return 1;
      case ReportPeriod.quarterly:
        return 3;
      case ReportPeriod.semiannual:
        return 6;
      case ReportPeriod.annual:
        return 12;
    }
  }
}
