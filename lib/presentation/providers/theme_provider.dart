import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;
  
  // Constructor that takes initial isDarkMode value
  ThemeProvider({bool isDarkMode = true}) : _isDarkMode = isDarkMode;
  
  bool get isDarkMode => _isDarkMode;
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    // Save theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }
} 