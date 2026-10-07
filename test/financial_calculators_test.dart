
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Financial Calculators Mathematical Accuracy Tests', () {
    test('Loan EMI Formula matches Standard Banking Amortization', () {
      const p = 500000.0;
      const annualRate = 10.5;
      const years = 5;

      final r = (annualRate / 12) / 100;
      final n = years * 12; // 60 months

      final powFactor = pow(1 + r, n).toDouble();
      final emi = (p * r * powFactor) / (powFactor - 1);

      // Expected EMI for 5L at 10.5% for 5 years is ~ 10,747
      expect(emi.round(), 10747);

      final totalPayment = emi * n;
      final totalInterest = totalPayment - p;

      expect(totalPayment > p, true);
      expect(totalInterest.round(), 144817);
    });

    test('SIP Compounding Formula matches Mutual Fund Standard Returns', () {
      const p = 5000.0; // monthly
      const annualRate = 12.0; // 12% p.a.
      const years = 10; // 10 years (120 months)

      final i = (annualRate / 12) / 100; // 0.01 per month
      final n = years * 12;

      final totalInvested = p * n;
      expect(totalInvested, 600000.0);

      final powFactor = pow(1 + i, n).toDouble();
      final totalMaturity = p * ((powFactor - 1) / i) * (1 + i);

      // Expected maturity for 5k/mo at 12% for 10 years is approx 11.61 Lakhs
      expect(totalMaturity > 1150000, true);
      expect(totalMaturity < 1170000, true);

      final wealthGain = totalMaturity - totalInvested;
      expect(wealthGain > 550000, true);
    });

    test('Lump Sum Compound Interest Formula is strictly accurate', () {
      const p = 100000.0;
      const annualRate = 12.0;
      const years = 5;

      final r = annualRate / 100;
      final totalVal = p * pow(1 + r, years).toDouble();

      // 1 Lakh compounded at 12% for 5 years = ~ 1,76,234
      expect(totalVal.round(), 176234);
    });
  });
}
