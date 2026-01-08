import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_extension/src/theme/extension_theme.dart';

void main() {
  group('ExtensionTheme', () {
    test('darkTheme returns a non-null ThemeData', () {
      final theme = ExtensionTheme.darkTheme;
      expect(theme, isA<ThemeData>());
      expect(theme, isNotNull);
    });

    test('darkTheme has dark brightness', () {
      final theme = ExtensionTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
    });

    test('darkTheme has correct scaffold background color', () {
      final theme = ExtensionTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0D1117));
    });

    test('darkTheme has correct primary color', () {
      final theme = ExtensionTheme.darkTheme;
      expect(theme.primaryColor, const Color(0xFF6366F1));
    });

    test('darkTheme has correct color scheme', () {
      final theme = ExtensionTheme.darkTheme;
      final colorScheme = theme.colorScheme;

      expect(colorScheme.primary, const Color(0xFF6366F1));
      expect(colorScheme.secondary, const Color(0xFF8B5CF6));
      expect(colorScheme.surface, const Color(0xFF161B22));
      expect(colorScheme.error, const Color(0xFFF85149));
      expect(colorScheme.brightness, Brightness.dark);
    });

    test('darkTheme has correctly configured text theme', () {
      final theme = ExtensionTheme.darkTheme;
      final textTheme = theme.textTheme;

      expect(textTheme.bodyLarge?.color, const Color(0xFFC9D1D9));
      expect(textTheme.bodyMedium?.color, const Color(0xFFC9D1D9));
      expect(textTheme.bodySmall?.color, const Color(0xFF8B949E));
    });

    test('darkTheme has correctly configured card theme', () {
      final theme = ExtensionTheme.darkTheme;
      final cardTheme = theme.cardTheme;

      expect(cardTheme.color, const Color(0xFF161B22));
      expect(cardTheme.elevation, 0);
      expect(cardTheme.shape, isA<RoundedRectangleBorder>());

      final shape = cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.color, const Color(0xFF30363D));
    });

    test('darkTheme has correctly configured divider theme', () {
      final theme = ExtensionTheme.darkTheme;
      final dividerTheme = theme.dividerTheme;

      expect(dividerTheme.color, const Color(0xFF30363D));
      expect(dividerTheme.thickness, 1);
    });

    test('darkTheme has correctly configured input decoration theme', () {
      final theme = ExtensionTheme.darkTheme;
      final inputTheme = theme.inputDecorationTheme;

      expect(inputTheme.filled, true);
      expect(inputTheme.fillColor, const Color(0xFF0D1117));
      expect(inputTheme.border, isA<OutlineInputBorder>());
      expect(inputTheme.enabledBorder, isA<OutlineInputBorder>());
      expect(inputTheme.focusedBorder, isA<OutlineInputBorder>());

      // Check border colors
      final enabledBorder = inputTheme.enabledBorder as OutlineInputBorder;
      expect(enabledBorder.borderSide.color, const Color(0xFF30363D));

      final focusedBorder = inputTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, const Color(0xFF6366F1));
    });

    test('darkTheme has correctly configured chip theme', () {
      final theme = ExtensionTheme.darkTheme;
      final chipTheme = theme.chipTheme;

      expect(chipTheme.backgroundColor, const Color(0xFF21262D));
      expect(chipTheme.side?.color, const Color(0xFF30363D));
      expect(chipTheme.shape, isA<RoundedRectangleBorder>());

      final labelStyle = chipTheme.labelStyle;
      expect(labelStyle?.color, const Color(0xFF8B949E));
    });

    test('darkTheme has correctly configured icon button theme', () {
      final theme = ExtensionTheme.darkTheme;
      final iconButtonTheme = theme.iconButtonTheme;

      expect(iconButtonTheme.style, isNotNull);
      // The foreground color is set via IconButton.styleFrom
      // which applies the color to the button's foreground
    });

    test('darkTheme color scheme is internally consistent', () {
      final theme = ExtensionTheme.darkTheme;

      // Primary color should match between top-level and color scheme
      expect(theme.primaryColor, theme.colorScheme.primary);
      expect(theme.colorScheme.primary, const Color(0xFF6366F1));
    });

    test('darkTheme uses GitHub-inspired dark colors', () {
      final theme = ExtensionTheme.darkTheme;

      // Verify the main background color (similar to GitHub dark)
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0D1117));

      // Verify the surface color (similar to GitHub dark code blocks)
      expect(theme.colorScheme.surface, const Color(0xFF161B22));

      // Verify the border color (GitHub dark borders)
      final cardTheme = theme.cardTheme;
      final shape = cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.color, const Color(0xFF30363D));
    });

    test('darkTheme chip selected color has correct opacity', () {
      final theme = ExtensionTheme.darkTheme;
      final chipTheme = theme.chipTheme;

      // The selected color should be primary with 0.3 alpha
      expect(chipTheme.selectedColor, isNotNull);

      // Verify it's based on primary color with transparency
      final primaryColor = const Color(0xFF6366F1);
      final expectedColor = primaryColor.withValues(alpha: 0.3);
      expect(chipTheme.selectedColor, expectedColor);
    });

    test('darkTheme card border radius is 8', () {
      final theme = ExtensionTheme.darkTheme;
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      final borderRadius = cardShape.borderRadius as BorderRadius;

      // All corners should have radius 8
      expect(borderRadius.topLeft.x, 8);
      expect(borderRadius.topRight.x, 8);
      expect(borderRadius.bottomLeft.x, 8);
      expect(borderRadius.bottomRight.x, 8);
    });

    test('darkTheme chip border radius is 16', () {
      final theme = ExtensionTheme.darkTheme;
      final chipShape = theme.chipTheme.shape as RoundedRectangleBorder;
      final borderRadius = chipShape.borderRadius as BorderRadius;

      // All corners should have radius 16
      expect(borderRadius.topLeft.x, 16);
      expect(borderRadius.topRight.x, 16);
      expect(borderRadius.bottomLeft.x, 16);
      expect(borderRadius.bottomRight.x, 16);
    });

    test('darkTheme input decoration border radius is 8', () {
      final theme = ExtensionTheme.darkTheme;
      final border = theme.inputDecorationTheme.border as OutlineInputBorder;
      final borderRadius = border.borderRadius;

      // All corners should have radius 8
      expect(borderRadius.topLeft.x, 8);
      expect(borderRadius.topRight.x, 8);
      expect(borderRadius.bottomLeft.x, 8);
      expect(borderRadius.bottomRight.x, 8);
    });
  });
}
