import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;

  const ThemeState({this.themeMode = ThemeMode.system});

  bool get isDark => themeMode == ThemeMode.dark;
  bool get isLight => themeMode == ThemeMode.light;
  bool get isSystem => themeMode == ThemeMode.system;

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }

  Map<String, dynamic> toJson() => {'themeMode': themeMode.index};

  factory ThemeState.fromJson(Map<String, dynamic> json) {
    final index = json['themeMode'] as int? ?? 0;
    return ThemeState(
      themeMode: ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)],
    );
  }

  @override
  List<Object?> get props => [themeMode];
}
