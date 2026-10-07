import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:money_reminder_app/providers/auth_provider.dart';
import 'package:money_reminder_app/screens/auth/login_screen.dart';
import 'package:money_reminder_app/screens/auth/register_screen.dart';
import 'package:money_reminder_app/screens/auth/forgot_password_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child, {Size size = const Size(360, 800)}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Auth Screens Render & Layout Tests', () {
    testWidgets('LoginScreen renders without overflow on 320px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(buildTestableWidget(const LoginScreen(), size: const Size(320, 700)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterScreen renders without overflow on 320px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(buildTestableWidget(const RegisterScreen(), size: const Size(320, 700)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ForgotPasswordScreen renders without overflow on 320px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(buildTestableWidget(const ForgotPasswordScreen(), size: const Size(320, 700)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('OtpVerificationScreen renders without overflow on 320px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(buildTestableWidget(
        const OtpVerificationScreen(email: 'test@example.com'),
        size: const Size(320, 700),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ResetPasswordScreen renders without overflow on 320px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(buildTestableWidget(
        const ResetPasswordScreen(email: 'test@example.com'),
        size: const Size(320, 700),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
