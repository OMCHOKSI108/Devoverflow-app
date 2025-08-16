// lib/features/settings/presentation/cubit/settings_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;

  const SettingsState({this.themeMode = ThemeMode.dark});

  @override
  List<Object> get props => [themeMode];
}
