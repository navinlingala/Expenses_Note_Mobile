class DashboardMetrics {
  final double totalToReceive;
  final double totalToPay;
  final double totalMonthlyEmis;
  final double monthlyCredit;
  final double monthlyDebit;
  final int overdueCount;
  final int upcomingCount;

  DashboardMetrics({
    this.totalToReceive = 0.0,
    this.totalToPay = 0.0,
    this.totalMonthlyEmis = 0.0,
    this.monthlyCredit = 0.0,
    this.monthlyDebit = 0.0,
    this.overdueCount = 0,
    this.upcomingCount = 0,
  });

  double get netCashflow => monthlyCredit - monthlyDebit;
  double get totalMonthlyCommitment => totalToPay + totalMonthlyEmis;
}
