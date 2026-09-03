import 'package:shared_preferences/shared_preferences.dart';

/// Small persisted app-wide preferences (currently just the currency symbol
/// the team uses, since "office" teams span many countries).
class SettingsStore {
  static const _currencyKey = 'officesplit.currency.v1';

  static const List<String> currencyOptions = ['₹', '\$', '€', '£', '¥'];

  Future<String> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? '₹';
  }

  Future<void> saveCurrency(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, symbol);
  }
}
