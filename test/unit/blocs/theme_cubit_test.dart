import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inum/presentation/blocs/theme/theme_state.dart';

void main() {
  group('ThemeState', () {
    test('default is system mode', () {
      const state = ThemeState();
      expect(state.themeMode, ThemeMode.system);
      expect(state.isSystem, true);
      expect(state.isDark, false);
      expect(state.isLight, false);
    });

    test('isDark is true for dark mode', () {
      const state = ThemeState(themeMode: ThemeMode.dark);
      expect(state.isDark, true);
      expect(state.isLight, false);
      expect(state.isSystem, false);
    });

    test('isLight is true for light mode', () {
      const state = ThemeState(themeMode: ThemeMode.light);
      expect(state.isLight, true);
      expect(state.isDark, false);
    });

    test('copyWith overrides themeMode', () {
      const state = ThemeState();
      final updated = state.copyWith(themeMode: ThemeMode.dark);
      expect(updated.isDark, true);
    });

    test('toJson serializes themeMode as index', () {
      const state = ThemeState(themeMode: ThemeMode.dark);
      final json = state.toJson();
      expect(json['themeMode'], ThemeMode.dark.index);
    });

    test('fromJson restores themeMode', () {
      final state = ThemeState.fromJson({'themeMode': ThemeMode.light.index});
      expect(state.themeMode, ThemeMode.light);
    });

    test('fromJson handles missing key', () {
      final state = ThemeState.fromJson({});
      expect(state.themeMode, ThemeMode.system);
    });

    test('fromJson clamps invalid index', () {
      final state = ThemeState.fromJson({'themeMode': 999});
      // Should clamp to valid range
      expect(ThemeMode.values.contains(state.themeMode), true);
    });

    test('equality via Equatable', () {
      const a = ThemeState(themeMode: ThemeMode.dark);
      const b = ThemeState(themeMode: ThemeMode.dark);
      expect(a, equals(b));

      const c = ThemeState(themeMode: ThemeMode.light);
      expect(a, isNot(equals(c)));
    });

    test('toJson and fromJson round-trip all modes', () {
      for (final mode in ThemeMode.values) {
        final state = ThemeState(themeMode: mode);
        final restored = ThemeState.fromJson(state.toJson());
        expect(restored.themeMode, mode);
      }
    });
  });
}
