// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FIX: Corrected the import path to use your actual project name.
import 'package:devoverflow/main.dart';

void main() {
  // FIX: Updated the test to check for the SplashScreen instead of the old counter app.
  testWidgets('App starts and shows splash screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // The MyApp widget is still the root of your application.
    await tester.pumpWidget(const MyApp());

    // We expect the app to show the splash screen. Let's verify that
    // the copyright text is present on the splash screen.
    expect(find.text('© 2025 Om and Dev. All rights reserved.'), findsOneWidget);

    // You can add more tests here, for example, waiting for the animation to complete
    // and verifying that the WelcomeScreen appears.
    // For example:
    // await tester.pumpAndSettle(const Duration(seconds: 5)); // Wait for timers to finish
    // expect(find.text('Welcome to DevOverflow'), findsOneWidget);
  });
}
