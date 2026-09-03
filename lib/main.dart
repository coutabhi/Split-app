import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/bill_store.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';
import 'widgets/currency_scope.dart';

void main() {
  runApp(const OfficeSplitApp());
}

class OfficeSplitApp extends StatefulWidget {
  const OfficeSplitApp({super.key});

  @override
  State<OfficeSplitApp> createState() => _OfficeSplitAppState();
}

class _OfficeSplitAppState extends State<OfficeSplitApp> {
  final _billStore = BillStore();
  final _settingsStore = SettingsStore();
  String _currency = '₹';

  @override
  void initState() {
    super.initState();
    _settingsStore.loadCurrency().then((c) {
      if (mounted) setState(() => _currency = c);
    });
  }

  void _setCurrency(String symbol) {
    setState(() => _currency = symbol);
    _settingsStore.saveCurrency(symbol);
  }

  @override
  Widget build(BuildContext context) {
    return CurrencyScope(
      symbol: _currency,
      setSymbol: _setCurrency,
      child: MaterialApp(
        title: 'OfficeSplit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: HomeScreen(store: _billStore),
      ),
    );
  }
}
