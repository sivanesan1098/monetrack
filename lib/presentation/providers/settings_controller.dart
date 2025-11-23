import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_controller.g.dart';

@riverpod
class SettingsController extends _$SettingsController {
  static const _kAutoAddKey = 'auto_add';
  static const _kCurrencyKey = 'currency';
  static const _kThemeModeKey = 'theme_mode';

  @override
  Future<Map<String, dynamic>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'autoAdd': prefs.getBool(_kAutoAddKey) ?? false,
      'currency': prefs.getString(_kCurrencyKey) ?? 'INR',
      'themeMode': prefs.getString(_kThemeModeKey) ?? 'system',
    };
  }

  Future<void> toggleAutoAdd(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoAddKey, value);
    state = AsyncValue.data({...state.value!, 'autoAdd': value});
  }

  Future<void> setCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyKey, value);
    state = AsyncValue.data({...state.value!, 'currency': value});
  }

  Future<void> setThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, value);
    state = AsyncValue.data({...state.value!, 'themeMode': value});
  }
}
