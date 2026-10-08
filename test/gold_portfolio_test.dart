import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:money_reminder_app/models/gold_asset_model.dart';
import 'package:money_reminder_app/providers/gold_provider.dart';
import 'package:money_reminder_app/providers/auth_provider.dart';
import 'package:money_reminder_app/screens/gold/gold_portfolio_screen.dart';
import 'package:money_reminder_app/screens/gold/add_edit_gold_asset_screen.dart';
import 'package:money_reminder_app/screens/gold/gold_asset_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoldAssetModel Unit & Financial Tests', () {
    test('Calculates weight in Tolas correctly', () {
      final asset = GoldAssetModel(
        id: 'gold_1',
        userId: 'user_1',
        title: '22K Gold Necklace',
        goldType: 'JEWELRY',
        purity: '22K_916',
        weightInGrams: 24.50,
        purchasePricePerGram: 6000.0,
        makingCharges: 3000.0,
        totalInvestedAmount: 150000.0,
        purchaseDate: DateTime(2023, 1, 1),
      );

      expect(asset.weightInTolas, 2.45);
      expect(asset.isJewelry, isTrue);
      expect(asset.isSgb, isFalse);
    });

    test('Calculates current valuation and SGB interest correctly', () {
      final sgb = GoldAssetModel(
        id: 'sgb_1',
        userId: 'user_1',
        title: 'SGB 2023 Series IV',
        goldType: 'SGB',
        purity: '24K',
        weightInGrams: 10.0,
        purchasePricePerGram: 6000.0,
        totalInvestedAmount: 60000.0,
        sgbInterestRate: 2.50,
        purchaseDate: DateTime(2023, 6, 1),
      );

      // Current 24K rate = 7650
      final currentVal = sgb.calculateCurrentValue(current24KRatePerGram: 7650.0);
      expect(currentVal, 76500.0);
      expect(sgb.absoluteGain(current24KRatePerGram: 7650.0), 16500.0);
      expect(sgb.gainPercentage(current24KRatePerGram: 7650.0), closeTo(27.5, 0.1));

      // SGB 2.5% of 60,000 = 1500/year, 750 semi-annual
      expect(sgb.sgbAnnualInterest, 1500.0);
      expect(sgb.sgbSemiAnnualInterest, 750.0);
      expect(sgb.isSgb, isTrue);
    });
  });

  group('Gold Screens Responsive Render Tests (320px Width)', () {
    Widget buildTestHarness(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => GoldProvider()),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('GoldPortfolioScreen renders without overflow on 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestHarness(const GoldPortfolioScreen()));
      await tester.pump();

      expect(find.text('Gold Assets & Wealth'), findsOneWidget);
      expect(find.text('Add Gold Asset'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddEditGoldAssetScreen renders without overflow on 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestHarness(const AddEditGoldAssetScreen()));
      await tester.pump();

      expect(find.text('Add Gold Asset'), findsOneWidget);
      expect(find.text('Gold Asset Type'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GoldAssetDetailScreen renders without overflow on 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sampleAsset = GoldAssetModel(
        id: 'gold_demo',
        userId: 'user_1',
        title: '22K Wedding Bangles',
        goldType: 'JEWELRY',
        purity: '22K_916',
        weightInGrams: 32.0,
        purchasePricePerGram: 5800.0,
        makingCharges: 4000.0,
        totalInvestedAmount: 189600.0,
        purchaseDate: DateTime(2022, 10, 15),
        lockerLocation: 'SBI Main Locker #104',
        huidNumber: 'HUID8831',
        jewelerName: 'Tanishq Jewellers',
      );

      await tester.pumpWidget(buildTestHarness(GoldAssetDetailScreen(asset: sampleAsset)));
      await tester.pump();

      expect(find.text('Asset Details'), findsOneWidget);
      expect(find.text('22K Wedding Bangles'), findsOneWidget);
      expect(find.text('32.00 g'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
