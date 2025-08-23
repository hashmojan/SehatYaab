import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sehatyab/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Initialize the ThemeController
    final themeController = ThemeController();
    Get.put(themeController);

    // Set initial theme to light
    themeController.setTheme(false);

    // Build our app (no need for initialThemeMode parameter anymore)
    await tester.pumpWidget(const MyApp());

    // Verify initial state
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Test interaction
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify update
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);

    // Clean up GetX bindings
    Get.reset();
  });

  // Add a new test for theme switching
  testWidgets('Theme switches between light and dark', (WidgetTester tester) async {
    final themeController = ThemeController();
    Get.put(themeController);

    await tester.pumpWidget(const MyApp());

    // Verify initial light theme
    expect(themeController.isDarkMode.value, false);
    expect(Get.isDarkMode, false);

    // Change to dark theme
    themeController.toggleTheme(true);
    await tester.pump();

    // Verify dark theme
    expect(themeController.isDarkMode.value, true);
    expect(Get.isDarkMode, true);

    Get.reset();
  });
}